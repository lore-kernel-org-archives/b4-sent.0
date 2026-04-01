From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/3] SHIFT 6MQ SD-card support, improved responsivness
 of touchscreen, and codec
Date: Wed, 01 Apr 2026 18:51:42 +0200
Message-Id: <20260401-axolotl-misc-p1-v2-0-f3af384bbb50@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAB5NzWkC/3WNQQ6CMBBFr0Jm7Zi2SgOuvIdhAe0gkyAlbdOgp
 He3snf5XvLf3yGQZwpwq3bwlDiwWwqoUwVm6pcnIdvCoITS4qIE9pubXZzxxcHgKlELaa+NMKq
 2I5TV6mnk7Sg+usITh+j8+zhI8mf/t5JEgU1r2qEmMyhNd944ns0HupzzF8RQmiSsAAAA
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1000; i=david@ixit.cz;
 h=from:subject:message-id; bh=FsJz6Y1jrRhN+ynwVx9vj7KUeac32cCBJTfbABnR1WY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpzU0imtl4V2NbNr/u04qYY7qqupwkyMb1rtxzv
 1pQe+ECRDOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac1NIgAKCRBgAj/E00kg
 ckUJD/9DQYZLYiGyqpcxIzN7GcI31eYZwOliWB1/A6I6AwBFUDememBrYcaRI6CjJMmqh6qT5uA
 uJq6JHJN/75797xKtKJ0oHVK4YO5WT/rsbETJ7Wq/9y0N07/mmhCEZgxa0BI9qnxrzSE0I9mgiZ
 rKuIPh9MDdEe16co2wGy9D/IP3dOgEELPquFXDnVWbjofBmvp1AWEGVLmkTDFUwXBCMdIufqSf6
 SuSabZx0WjVK3RP3cdew46y0QOyWDOLGpTApLADgTATdJzudd+b9r7+XhXRWcONaqsT23E/DkUg
 9PlIzXMWTy4I2WV8wJppxzilmigTyDxOV+aBxul2gGls0QshAi67isu2uF5HafKOKA6j/7gF7zu
 c9DjoB9yznvpWjlPAjtg536Ne8EMOucmoWwkNulpcUjVZwpudbwiqfUnndsOVavVasl/lC4kMzK
 lasQBAd38mNthFNs3SqCNHoGqmxMfES7AWWpft6iVXiSWRC9sdgBZqgWZS9BtSSSv/mI06nJaIh
 Tkkrq6aJg5gn304C+UqD3DVjBvyVaECISGLilOW2azYnhPsl0NQUt0sp859y1Tp8a6tyf3Oval3
 uWgs7d4kcJDYdI0EJr7IuUxn74rZAU4zuXK9ibnUJ9s7exdtkk36qc73Bhki/SklA2Qbqxbmzlo
 63hszrO3Mn3Vrbg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I've tested that SD card and touchscreen works well, the codec does too,
but for complete enablement needs soundcard support which isn't fully
finished.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
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

