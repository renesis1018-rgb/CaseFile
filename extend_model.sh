#!/bin/bash

echo "━━━ Core Data モデル自動拡張 ━━━"
echo ""

python3 << 'PYTHON_EOF'
import xml.etree.ElementTree as ET
import os
import shutil

model_base = "CaseFile.xcdatamodeld"
original = os.path.join(model_base, "CaseFile.xcdatamodel")
new_model = os.path.join(model_base, "CaseFile 2.xcdatamodel")

print("Step 1: モデルバージョン作成...")
if os.path.exists(new_model):
    shutil.rmtree(new_model)
shutil.copytree(original, new_model)
print("  ✅ CaseFile 2 作成\n")

contents = os.path.join(new_model, "contents")
tree = ET.parse(contents)
root = tree.getroot()

print("Step 2: 属性追加...\n")

# Patient
patient = root.find(".//entity[@name='Patient']")
for name, typ in [("heightCm","Double"),("bodyWeightKg","Double"),("bmi","Double"),
                  ("maxBodyWeightKg","Double"),("breastFeedingHistory","String"),
                  ("smokingHistory","String"),("numberOfProcedures","Integer 16")]:
    el = ET.SubElement(patient, "attribute")
    el.set("name", name)
    el.set("optional", "YES")
    el.set("attributeType", typ)
    if typ != "String":
        el.set("usesScalarValueType", "YES")
print("  ✅ Patient: 7属性")

# Surgery
surgery = root.find(".//entity[@name='Surgery']")
for name in ["nacImfRight","nacImfLeft","nacImfStretchRight","nacImfStretchLeft",
             "skinThicknessRight","skinThicknessLeft","subcutaneousRight","subcutaneousLeft",
             "subglandularRight","subglandularLeft","submuscularRight","submuscularLeft",
             "decolleteRight","decolleteLeft"]:
    el = ET.SubElement(surgery, "attribute")
    el.set("name", name)
    el.set("optional", "YES")
    el.set("attributeType", "Double")
    el.set("usesScalarValueType", "YES")
print("  ✅ Surgery: 14属性")

# FollowUp
followup = root.find(".//entity[@name='FollowUp']")
for name, typ in [("vecturaVolumeRight","Double"),("vecturaVolumeLeft","Double"),
                  ("bodyWeightKg","Double"),("smokingStatus","String"),
                  ("alcoholConsumption","String"),("retentionRateRight","Double"),
                  ("retentionRateLeft","Double"),("o2Capsule","String")]:
    el = ET.SubElement(followup, "attribute")
    el.set("name", name)
    el.set("optional", "YES")
    el.set("attributeType", typ)
    if typ != "String":
        el.set("usesScalarValueType", "YES")
print("  ✅ FollowUp: 8属性")

# LabData
print("\n  🆕 LabData作成...")
labdata = ET.SubElement(root, "entity")
labdata.set("name", "LabData")
labdata.set("representedClassName", "LabData")
labdata.set("syncable", "YES")
labdata.set("codeGenerationType", "class")

id_attr = ET.SubElement(labdata, "attribute")
id_attr.set("name", "id")
id_attr.set("optional", "NO")
id_attr.set("attributeType", "UUID")
id_attr.set("usesScalarValueType", "NO")

for name in ["wbc","rbc","hemoglobin","hematocrit","mcv","mch","mchc","plateletCount",
             "prothrombinTime","ptTime","ptControl","ptActivity","ptInr","aptt",
             "totalProtein","uricAcid","bloodUreaNitrogen","indirectBilirubin","creatinine",
             "sodium","potassium","chloride","iron","totalCholesterol","triglycerides",
             "totalBilirubin","directBilirubin","ast","alt","gammaGt","alp","ldh",
             "fastingBloodSugar","hba1c","hbsAntigenValue","hcvAntibodyIndex"]:
    el = ET.SubElement(labdata, "attribute")
    el.set("name", name)
    el.set("optional", "YES")
    el.set("attributeType", "Double")
    el.set("usesScalarValueType", "YES")

for name in ["hbsAntigenResult","hbsAntibodyResult","hbsAntibodyValue",
             "hcvAntibodyResult","hcvAntibodyUnit","hivResult","rprResult",
             "syphilisTpResult","bloodTypeAbo","bloodTypeRh","otherTests"]:
    el = ET.SubElement(labdata, "attribute")
    el.set("name", name)
    el.set("optional", "YES")
    el.set("attributeType", "String")
print("  ✅ LabData: 49属性")

# PatientSatisfaction
print("  🆕 PatientSatisfaction作成...")
satisfaction = ET.SubElement(root, "entity")
satisfaction.set("name", "PatientSatisfaction")
satisfaction.set("representedClassName", "PatientSatisfaction")
satisfaction.set("syncable", "YES")
satisfaction.set("codeGenerationType", "class")

id_attr2 = ET.SubElement(satisfaction, "attribute")
id_attr2.set("name", "id")
id_attr2.set("optional", "NO")
id_attr2.set("attributeType", "UUID")
id_attr2.set("usesScalarValueType", "NO")

for name, typ in [("breastQScore","Double"),("assessmentDate","Date"),
                  ("satisfactionLevel","String"),("comments","String")]:
    el = ET.SubElement(satisfaction, "attribute")
    el.set("name", name)
    el.set("optional", "YES")
    el.set("attributeType", typ)
    el.set("usesScalarValueType", "YES" if typ == "Double" else "NO")
print("  ✅ PatientSatisfaction: 5属性")

# リレーション
print("\nStep 3: リレーション設定...\n")

rel1 = ET.SubElement(surgery, "relationship")
rel1.set("name", "labData")
rel1.set("optional", "YES")
rel1.set("maxCount", "1")
rel1.set("deletionRule", "Cascade")
rel1.set("destinationEntity", "LabData")
rel1.set("inverseName", "surgery")
rel1.set("inverseEntity", "LabData")

rel2 = ET.SubElement(labdata, "relationship")
rel2.set("name", "surgery")
rel2.set("optional", "YES")
rel2.set("maxCount", "1")
rel2.set("deletionRule", "Nullify")
rel2.set("destinationEntity", "Surgery")
rel2.set("inverseName", "labData")
rel2.set("inverseEntity", "Surgery")
print("  ✅ Surgery ↔ LabData")

rel3 = ET.SubElement(surgery, "relationship")
rel3.set("name", "patientSatisfaction")
rel3.set("optional", "YES")
rel3.set("maxCount", "1")
rel3.set("deletionRule", "Nullify")
rel3.set("destinationEntity", "PatientSatisfaction")
rel3.set("inverseName", "surgery")
rel3.set("inverseEntity", "PatientSatisfaction")

rel4 = ET.SubElement(satisfaction, "relationship")
rel4.set("name", "surgery")
rel4.set("optional", "YES")
rel4.set("maxCount", "1")
rel4.set("deletionRule", "Nullify")
rel4.set("destinationEntity", "Surgery")
rel4.set("inverseName", "patientSatisfaction")
rel4.set("inverseEntity", "Surgery")
print("  ✅ Surgery ↔ PatientSatisfaction")

tree.write(contents, encoding="UTF-8", xml_declaration=True)
print("\n  💾 保存完了")

print("\nStep 4: Current Version設定...\n")
plist = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>_XCCurrentVersionName</key>
<string>CaseFile 2.xcdatamodel</string>
</dict>
</plist>
'''
with open(os.path.join(model_base, ".xccurrentversion"), 'w') as f:
    f.write(plist)
print("  ✅ Current Version = CaseFile 2")

print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✅ 完了!")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

PYTHON_EOF

echo ""
echo "次のステップ:"
echo "  1. Xcode を開く"
echo "  2. Product → Clean Build Folder (⌘⇧K)"
echo "  3. Product → Build (⌘B)"
echo "  4. Product → Run (⌘R)"
echo ""
echo "⚠️  初回実行時にエラーが出た場合:"
echo "  → アプリを削除して再インストール"

