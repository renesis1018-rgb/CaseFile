#!/bin/bash

# Core Dataモデルファイルパス
MODEL_FILE="./CaseFile/CaseFile.xcdatamodeld/CaseFile 2.xcdatamodel/contents"

# バックアップ作成
cp "$MODEL_FILE" "$MODEL_FILE.backup"

# 新規追加する属性リスト
declare -a ATTRIBUTES=(
  "wbc,Double,白血球数"
  "rbc,Double,赤血球数"
  "hematocrit,Double,ヘマトクリット"
  "totalProtein,Double,総蛋白"
  "uricAcid,Double,尿酸"
  "bloodUreaNitrogen,Double,尿素窒素"
  "totalCholesterol,Double,総コレステロール"
  "triglyceride,Double,中性脂肪"
  "totalBilirubin,Double,総ビリルビン"
  "sodium,Double,ナトリウム"
  "potassium,Double,カリウム"
  "glucose,Double,血糖"
)

# LabDataエンティティの最後の</entity>タグの前に属性を挿入
for attr in "${ATTRIBUTES[@]}"; do
  IFS=',' read -r name type description <<< "$attr"
  
  # 属性XMLを生成
  ATTR_XML="        <attribute name=\"$name\" optional=\"YES\" attributeType=\"Double\" defaultValueString=\"0.0\" usesScalarValueType=\"YES\"/>"
  
  # LabDataエンティティ内に挿入
  sed -i '' "/<entity name=\"LabData\"/,/<\/entity>/ {
    /<\/entity>/i\\
$ATTR_XML
  }" "$MODEL_FILE"
done

echo "✅ LabDataエンティティに12個の属性を追加しました"
