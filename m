From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v4 0/9] Pixel 3 XL display panel support
Date: Wed, 25 Nov 2026 19:12:44 +0100
Message-Id: <20261125-crosshatch-panel-v4-0-120adc58e737@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23N0Q6CIBTG8VdxXEcDMsCueo/WBR4OSWvqwJzVf
 Pcwt2bLy287v/95kYjBYySH7EUC9j76pk4j32QEKlNfkHqbNhFMSKYZpxCaGCvTQUVbU+ONMgm
 ojSxcqRxJrA3o/PBJns7zjvfyitBNnemi8rFrwuPzs+fT3ZwvBPvP95wyalFisefCmkIe/eC7L
 TzJFO/FkucrXCTOtN2DKp0SDn757ss5Z3qF7xLXytocIXcKFnwcxzfKcvqWPgEAAA==
X-Change-ID: 20260801-crosshatch-panel-06ce8a69fb7f
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Petr Vorel <petr.vorel@gmail.com>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, Abel Vesa <abel.vesa@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2435; i=david@ixit.cz;
 h=from:subject:message-id; bh=YE6uRQHX3frxMj/6HJyZlh9S6ry+tb/5u1Co16RoWHM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrByUdjIHhZsyDm0D45ADd1nzAhvMIdNhRlEJ5d
 RCRlmigj2uJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawclHQAKCRBgAj/E00kg
 cg6PD/wIDgT0i2YnmMltMCXjiIiAXM7Tw57g64kdw/CpoMXAUVGO8gTBower1KaV9G1lfUZ3j/T
 adSF4+iDlSVVnvWSziJt1q9/IvBnuaG3gkZihfTny2Zu3cJzYMUZMYdESChgwU1ygiKcnrcl275
 6X5QS8Qc8ziYWAW9XHZLiAXP72IGpxMERZ10+jVix7nZZO7sP/SS9WkTuhGL4ngwXirv6gv2J5/
 QN54hIgeSn0joz7ixjB5sMgaa2LK1mLMLTigRv33fdczbAbfknRM03nCEf2HCc1ZDa/g16PQP6Y
 2376qchOrs1BIfcSZBnA3NgpptvHHF3j9QdDEGT+JIcp6zG/q/VpCchnWpC/qb8MI4jNFHIQNJ6
 wuSNepz4G0OLYjt419nikOg20EomKQ+MgCYVniixO4aOrMuMCKbzZNEVH9o5aly+A+dAPqFeDqF
 UOy4gFHtaN+2b7vtYVGOtXCXPv9v28GLA8fwtwGRsFPsmWh/t2k4G/LZQSz4A1sufMmOEGLxy1D
 EjlFh65pvCb3IBRnqYXDh/tDcT1Eml8uaN+HNijtMLTh+Hj1BBYKdSpd045bstPLcoW93Khkpii
 nKNSmXsH36ZUzTgiBCMjBC/bFPyJo2LzqBawhhQr7OIPcdGnmMvEmBg1hdIrhcWXKP25CtGaFuu
 Ca5N7Cd2m2xpfog==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce Samsung AMB630QY01 (Google Pixel 3 XL) panel.

Includes refactoring and improvements to the S6E3HA8 DDIC which is also
used by Samsung S9 (Korea version).

Patches 7 and 9 switch to the new compatibles, so they must not reach
the qcom tree before the driver patches land.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v4:
- Entire allOf goes after required: block. Now really. (Krzysztof)
- Improved wording of 1st commit. (Krzysztof)
- Link to v3: https://patch.msgid.link/20261108-crosshatch-panel-v3-0-87dd4ec4f7cc@ixit.cz

Changes in v3:
- Entire allOf goes after required: block. (Krzysztof)
- Expalin dt-bindings changes more explicitly. (Krzysztof)
- Dropped "Really assert reset on the failure" as requested by (Krzysztof)
- Not addressed: "No, this is wrong. You just broke all the users of
  this DTS.", due to non-existent usage outside of Linux and DTB for
  this device being shipped always together with the kernel.
- Link to v2: https://patch.msgid.link/20260924-crosshatch-panel-v2-0-08d5c7bf72fc@ixit.cz

Changes in v2:
- Rebase on top of next-20260923.
- Cosmetic fix s/Cosmtetic/Cosmetic/ fix in the commit msg. (Neil)
- Link to v1: https://patch.msgid.link/20260920-crosshatch-panel-v1-0-de6e9512da96@ixit.cz

---
David Heidelberg (9):
      dt-bindings: display: panel: s6e3ha8: Adjust to reflect the DDIC and panel used
      dt-bindings: display: panel: s6e3ha8: Add AMB630QY01 panel
      drm/panel: s6e3ha8: Introduce AMB577PX01 panel compatible
      drm/panel: s6e3ha8: Prepare for supporting multiple panels
      drm/panel: s6e3ha8: Correct the polarity logic within
      drm/panel: s6e3ha8: Assert reset GPIO in unprepare
      drm/panel: s6e3ha8: Add Samsung AMB630QY01 (Google Pixel 3 XL) panel
      arm64: dts: qcom: sdm845-samsung-starqltechn: Update panel compatible
      arm64: dts: qcom: sdm845-google-crosshatch: Add display panel

 .../bindings/display/panel/samsung,s6e3ha8.yaml    |  52 +++-
 .../boot/dts/qcom/sdm845-google-crosshatch.dts     |  60 +++-
 .../boot/dts/qcom/sdm845-samsung-starqltechn.dts   |   4 +-
 drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c      | 304 +++++++++++++++++----
 4 files changed, 354 insertions(+), 66 deletions(-)
---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20260801-crosshatch-panel-06ce8a69fb7f

Best regards,
--  
David Heidelberg <david@ixit.cz>

