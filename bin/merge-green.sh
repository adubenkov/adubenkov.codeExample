#!/bin/sh
# Слияние PR только при зелёных проверках — замена серверной защите ветки.
#
# Эталон канона: dev-process/templates/merge-green.sh. Копия в проекте —
# bin/merge-green.sh (сеет process-init, расхождение видит process-doctor).
#
# ЗАЧЕМ. Регламент сам признаёт дыру: required status checks на приватном
# репозитории free-плана недоступны, «формулу держит manager по gh pr checks»
# — то есть держит ПАМЯТЬ того, кто жмёт merge. Память однажды не удержала:
# в одном из проектов PR уехал в main при красной проверке (продукт не
# пострадал). Поэтому решение принимает скрипт, а не человек в конце длинного
# хода. Правило, переведённое в механику, из прозы ролей удаляется — так же,
# как запреты, ушедшие в хук.
#
#   sh bin/merge-green.sh 81             слить PR #81 (squash + удалить ветку)
#   DRY_RUN=1 sh bin/merge-green.sh 81   напечатать решение, не сливая
#   sh bin/merge-green.sh --self-test    проверить разбор аргументов
#
# Источник истины — структурированный вывод gh, а не разбор человекочитаемого
# текста: `gh pr view --json` и `gh pr checks --json`, разбор через jq.
#
# Отказывает (одна строка на причину, код возврата 1), если:
#   - номер PR не передан или не число;
#   - PR не существует или недоступен;
#   - PR не OPEN (уже слит или закрыт — сливать нечего);
#   - PR черновик;
#   - PR не MERGEABLE (конфликт с main либо GitHub ещё не посчитал);
#   - на PR нет ни одной проверки (пустой набор — не «всё зелено»);
#   - есть незавершённые проверки;
#   - хоть одна проверка не в бакете pass.
#
# Вердикт ревью проверяется тем же путём: `gate` это commit status, и красный
# или отсутствующий на продуктовом PR `gate` попадёт в число незелёных проверок
# (docs/TEAM.md, «Два имени, не путать»).
set -eu

usage() {
  echo "нужен номер PR: sh bin/merge-green.sh <N>   (или --self-test)"
}

# Проверка разбора аргументов без сети: гейт, не проверивший сам себя, тихо
# зеленеет на сломанном входе.
self_test() {
  fails=0
  check() {
    if [ "$2" != "$3" ]; then
      echo "ПРОВАЛ: $1 — получили «$2», ждали «$3»" >&2
      fails=$((fails + 1))
    fi
  }
  check "пусто — не номер" "$(valid_pr '' && echo да || echo нет)" "нет"
  check "буквы — не номер" "$(valid_pr abc && echo да || echo нет)" "нет"
  check "дробь — не номер" "$(valid_pr 1.5 && echo да || echo нет)" "нет"
  check "минус — не номер" "$(valid_pr -3 && echo да || echo нет)" "нет"
  check "число — номер" "$(valid_pr 81 && echo да || echo нет)" "да"
  check "ноль — не номер" "$(valid_pr 0 && echo да || echo нет)" "нет"
  if [ "$fails" -ne 0 ]; then
    echo "самопроверка: $fails провалов" >&2
    return 1
  fi
  echo "самопроверка: всё зелено"
  return 0
}

valid_pr() {
  case "${1:-}" in
    '' | *[!0-9]*) return 1 ;;
    0) return 1 ;;
    *) return 0 ;;
  esac
}

if [ "${1:-}" = "--self-test" ]; then
  self_test
  exit $?
fi

command -v jq >/dev/null 2>&1 || {
  echo "нужен jq для разбора вывода gh (brew install jq)"
  exit 1
}

PR="${1:-}"
valid_pr "$PR" || {
  usage
  [ -n "$PR" ] && echo "номер PR должен быть положительным числом, получено: $PR"
  exit 1
}

DRY_RUN="${DRY_RUN:-0}"

VIEW_JSON=$(gh pr view "$PR" --json state,isDraft,mergeable,title 2>&1) || {
  echo "отказ: PR #$PR не найден или недоступен"
  echo "$VIEW_JSON"
  exit 1
}

STATE=$(printf '%s' "$VIEW_JSON" | jq -r '.state')
IS_DRAFT=$(printf '%s' "$VIEW_JSON" | jq -r '.isDraft')
MERGEABLE=$(printf '%s' "$VIEW_JSON" | jq -r '.mergeable')

if [ "$STATE" != "OPEN" ]; then
  echo "отказ: PR #$PR не открыт (state=$STATE) — сливать нечего"
  exit 1
fi

if [ "$IS_DRAFT" = "true" ]; then
  echo "отказ: PR #$PR — черновик, сначала пометь готовым к ревью"
  exit 1
fi

if [ "$MERGEABLE" != "MERGEABLE" ]; then
  if [ "$MERGEABLE" = "CONFLICTING" ]; then
    echo "отказ: PR #$PR конфликтует с main — доведи ветку слиянием (не ребейзом: force-push режется хуком)"
  else
    echo "отказ: GitHub ещё не посчитал совместимость (mergeable=$MERGEABLE) — повтори через минуту"
  fi
  exit 1
fi

# Код возврата 8 у `gh pr checks` значит «не все зелёные», а не сбой вызова.
CHECKS_JSON=$(gh pr checks "$PR" --json name,state,bucket 2>&1) || CHECKS_RC=$?
CHECKS_RC="${CHECKS_RC:-0}"
if [ "$CHECKS_RC" -ne 0 ] && [ "$CHECKS_RC" -ne 8 ]; then
  case "$CHECKS_JSON" in
    \[*) ;;
    *)
      echo "отказ: не удалось получить проверки PR #$PR"
      echo "$CHECKS_JSON"
      exit 1
      ;;
  esac
fi

CHECK_COUNT=$(printf '%s' "$CHECKS_JSON" | jq 'length')
if [ "$CHECK_COUNT" -eq 0 ]; then
  echo "отказ: на PR #$PR ещё нет ни одной проверки"
  exit 1
fi

PENDING=$(printf '%s' "$CHECKS_JSON" | jq '[.[] | select(.bucket=="pending")] | length')
if [ "$PENDING" -gt 0 ]; then
  echo "отказ: есть незавершённые проверки на PR #$PR:"
  printf '%s' "$CHECKS_JSON" | jq -r '.[] | select(.bucket=="pending") | "  - " + .name'
  exit 1
fi

FAILING=$(printf '%s' "$CHECKS_JSON" | jq '[.[] | select(.bucket!="pass")] | length')
if [ "$FAILING" -gt 0 ]; then
  echo "отказ: не все проверки зелёные на PR #$PR:"
  printf '%s' "$CHECKS_JSON" | jq -r '.[] | select(.bucket!="pass") | "  - " + .name + ": " + .bucket'
  exit 1
fi

printf 'зелёный свет: PR #%s готов к слиянию\n' "$PR"
if [ "$DRY_RUN" = "1" ]; then
  echo "DRY_RUN=1 — слияние не выполняется"
  exit 0
fi

gh pr merge "$PR" --squash --delete-branch
