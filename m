From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 0/3] SHIFT 6MQ SD-card support, improved responsivness
 of touchscreen, and codec
Date: Thu, 02 Apr 2026 11:54:05 +0200
Message-Id: <20260402-axolotl-misc-p1-v3-0-8934e9db6831@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL08zmkC/3WNwQqDMBAFf0Vybspmo6I9+R+lBxOTumCNJBJsx
 X9v9OKh9DgPZt7KgvFkArtlK/MmUiA3JpCXjOm+HZ+GU5eYIWAJEoG3ixvcPPAXBc0nwUsQXV6
 BxqKzLFmTN5aWo3h/JO4pzM6/j4Mo9vV/KwoOvKp1rQqjFZamoYXmq/6wvRTxtHMQvzYm28rWy
 ipXShVw2tu2fQHemk386gAAAA==
X-Change-ID: 20260320-axolotl-misc-p1-601d480c25df
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dylan Van Assche <me@dylanvanassche.be>
Cc: linux-arm-msm@vger.kernel.org, Petr Hodina <phodina@protonmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1146; i=david@ixit.cz;
 h=from:subject:message-id; bh=g8X7jdbCgWRJVgbstnTrfuS11/pgXSaoaMN5ZccW5G8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpzjy/pvCpctAMVvZY8W5n9dTG/nudXwKmeTXHn
 nL+UMXqjIuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac48vwAKCRBgAj/E00kg
 coJjD/4uCUKkiei3H4sL5HGCOEslH6+dfqYlpBJOdXAX5M125RAh6AjVsldTUClwWP5JsYabSDA
 HlHP2CrERCZ5gE+adrPCvcRB1bcMylD3GgYIu9mIHIqQQ9P1Ep98Yf9jrqneIrximq8YwrEpP5Y
 vr+XXWrNjxVHQZDqodnoL/lebmBwGGVb1w3GqUwMfd8rQYMi7v07hm9X87nVxRNVs8zcOT7JLXd
 zT0AX9fkNe8pZlS+q61n65kU7J02L88Od4s8QloelzLZEHvREPP8gjqFSUJk5WDA3pEy0eox9cd
 ZofYqRSelqvEGHG6o2UpaW6DIH5hBsIbnZJMhxoW/3AnkoXGJ37vNx0wGEWFbmSupPfGISVQ23C
 E9LjQsCSnjkH7fpQfpHW/q0GPHPa462JdXNQg1a/6Mm8X7hIV6eLALL8qCRDts6xregdgkkPlK2
 91Cq1Ju7vNrD6fUC4EXfjrsn8xuv1FqeaTs3anMZWcTiU+Jmo+nnMJVok3k4AxavqYDbUCgIcjF
 nxHxoH6UMZJY0Qx4b8LRNaDNsW8hq+h8yM7EayjMu1ZjF+rmZ7wuEKCpYNXr1MlVIaasguz7uFo
 eRdSuhHXK3GWoR9hP8ddzelZyQLt8bsAfFxBDNwajNbVaqrpQTUwQuJMzoMK+lsjNqVl8r/k58t
 ylTa7v5dVyitv8A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I've tested that SD card and touchscreen works well, the codec does too,
but for complete enablement needs soundcard support which isn't fully
finished.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v3:
- sdcard property sorting (Konrad)
- Link to v2: https://lore.kernel.org/r/20260401-axolotl-misc-p1-v2-0-f3af384bbb50@ixit.cz

Changes in v2:
- Changed bias-pull-up to bias-disable for SD card detection, since the
  mechanism doesn't work, we can just save few uA. (Casey)
- Link to v1: https://lore.kernel.org/r/20260320-axolotl-misc-p1-v1-0-89c9b5ecb26e@ixit.cz

---
Alexander Martinz (1):
      arm64: dts: qcom: sdm845-shift-axolotl: Enable TFA9890 codec

Casey Connolly (2):
      arm64: dts: qcom: sdm845-shift-axolotl: Enable sdcard
      arm64: dts: qcom: sdm845-shift-axolotl: Set higher touchscreen i2c clock

 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 59 +++++++++++++++++++++++
 1 file changed, 59 insertions(+)
---
base-commit: bd0f139e5fc11182777b81cefc3893ea508544ec
change-id: 20260320-axolotl-misc-p1-601d480c25df

Best regards,
-- 
David Heidelberg <david@ixit.cz>

