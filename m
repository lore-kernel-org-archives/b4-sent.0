From: Esteban Urrutia <esteuwu@proton.me>
Subject: [PATCH 0/2] PM8350B LDO support
Date: Thu, 23 Jul 2026 10:53:51 -0400
Message-Id: <20260723-pm8350b-ldo-v1-0-42b5428a0d3f@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSQ5AQBBA0atIrXXSSgxxFbHooVBiSjciEXfXW
 L7F/xd4ckwequgCRwd7XuaAJI7A9GruSLANBpSYywJTsU5lmkktRruIokTUqrU5ZQZCsTpq+fx
 udfPb73ogs70LuO8HrkmlK28AAAA=
X-Change-ID: 20260723-pm8350b-ldo-7822bafd6e5c
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784818498; l=1005;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=bkBPbgCG+JwsJ/4CRQTu9uoshFqb+X/VXg4zAFDbW6A=;
 b=fYb5im4/MAI/XaEnIC8H+Hcm67yn2KYKv/Hx45tEz0gVAahSZh1uBkCrYAYFvieNn4TIibOwU
 +oL9Rml89bDD7X96HIJ4sCXGMU7qYvohKXxFGeRqYGwpmzOd2/eWdoP
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PM8350B PMIC has an LDO regulator which seems to be mostly used for
powering display driver ICs.
On my device's schematics, vdd-l1-supply is represented as VIN_DDIC, and
vdd-l1 is represented as VREG_DDIC.
Downstream this LDO is of type pmic5-ldo and I assume it should be of
type pmic5_nldo upstream, since this is the type of regulator with the
least margin error for the reference voltage, which is 1250-1296mV for
my device.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
Esteban Urrutia (2):
      regulator: dt-bindings: qcom,rpmh: Add support for PM8350B
      regulator: qcom-rpmh: Add support for PM8350B

 .../devicetree/bindings/regulator/qcom,rpmh-regulator.yaml    | 11 +++++++++++
 drivers/regulator/qcom-rpmh-regulator.c                       |  9 +++++++++
 2 files changed, 20 insertions(+)
---
base-commit: b4515cf4156356e8f4fe6e0fdc17f59adab9772f
change-id: 20260723-pm8350b-ldo-7822bafd6e5c

Best regards,
--  
Esteban Urrutia <esteuwu@proton.me>

