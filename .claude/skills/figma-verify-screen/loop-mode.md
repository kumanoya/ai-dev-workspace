# figma-verify-screen — mode: loop（例外運用）の手順

`mode: loop` は PASS まで修正を反復する例外運用。**ユーザーが明示的に指定した場合のみ**使う（例外条件は `docs/ai-cost-optimization.md` §7.3）。本ファイルは SKILL.md の手順4から、loop 明示時にのみ Read される。

## 追加入力

- **maxRounds**（任意）: 反復上限（既定 **3**）。critical/major は通常 1〜2 round で収束する。

## 判定と反復（SKILL.md 手順4の続き）

- `PASS` → ループ終了。最終所見と画像パスを報告。
- `FAIL` → **実装修正**:
  - findings（critical/major のみ着手。minor/nit は原則スキップし「残課題」として記録）を基に対象ファイルを編集。
    - **修正は基本メインエージェントが直接行う**（追加のサブエージェントを起動しない＝コスト節約）。
      複数ファイルにまたがる大規模修正のときだけ実装サブエージェントへ委譲する。
  - 修正後 `pnpm run lint` を通す。
  - **SKILL.md の手順2に戻る**（再スクショ → 再レビュー）。

## 停止条件（無限ループ・コスト暴走の防止。いずれか満たしたら停止しユーザーに報告）

- `verdict == PASS`、または
- `round >= maxRounds`、または
- **進捗なし**: 直近 2 round で critical/major の件数が減らない（同じ指摘が残る／新規が増える）。
  無理に回さず、残差分・原因の仮説・必要な判断（デザイナー確認/仕様未定）を一覧化して止める。

## loop 時のコスト原則（SKILL.md の共通原則に追加）

- 1 画面あたり **目安 3 round 以内**。それで PASS しないものは仕様・デザイン側の未確定が原因のことが多い。
- minor/nit のために round を重ねない。PASS（critical/major=0）を満たしたら止め、minor は spec/progress に残す。

## 仕上げ

- PASS した round 数・残った minor/nit・最終画像パスを要約。
- レビューで判明した「Figma 側の注記不足」は `docs/progress-*.md` のフェーズ3へ追記。

## Workflow 版（任意・大規模時）

複数画面を一括で「実装→検証→PASSまで修正」したい場合は、各画面を pipeline 化し、
`figma-screen-reviewer` を verify ステージに据えた Workflow を組む（ユーザーが明示的に依頼した場合のみ）。
