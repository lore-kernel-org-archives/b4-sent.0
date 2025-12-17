From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/2] Commonize pinctrl for camera master clock on
 Qualcomm SDM845
Date: Wed, 17 Dec 2025 12:39:22 +0100
Message-Id: <20251217-sdm845-mclk-v2-0-7028c2d09145@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGqWQmkC/23MQQ6CMBCF4auQWTumU1oRVt7DsMC2yEQB05IGJ
 b27lbXL/yXv2yA4zy5AU2zgXeTA85RDHgowQzfdHbLNDVJITZJKDHY8K42jeT5QKOplV2vpSoL
 8eHnX87pr1zb3wGGZ/XvHI/3W/04kFEh1dTO1qqwypwuvvBzNB9qU0hetZ2r0pAAAAA==
X-Change-ID: 20251213-sdm845-mclk-041f2a952e31
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1242; i=david@ixit.cz;
 h=from:subject:message-id; bh=p1WldwTrpRxChl17GG81aXsQPP0VK+RjvLUrIAeadkI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpQpZrq8sqGhUVWb/Yjh31dFIK16GVY0rutCj+y
 k6v1XfgPQuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaUKWawAKCRBgAj/E00kg
 cj++D/9CpnmSUr7ktdd0/7Rh7A6Db/IizlbNaQ//PCqlQskWX6ZpNASkia5n2IIuI1fP4YRux1A
 0upzKZ5oFl32RIEy5iz3oH9/c5iU3Ucco4imprJ3m36WfSADiDgOqT+cTZryLBu8QVMSxU/V/6i
 D7deIEDUEuchYiuyDxjxWdk2A/0B6+CrLj32VX9XoJLgiU8mJo0eCS/TlRhzacWDIATIFJWKA5J
 1PScJc9To8jxS6q6aal+OCgKIySeRvu2/J9v5pJI/Jx8LYwZd9GuJggWTiZEal16Bh4jJSEbxF4
 rYk6c2eb65+vv1rs/FtZtbFR1pZ/IGE2VFOPBAbgYUtdoiaGI7KGqd3rRDLTqw3+jUZ5v0Ql0GX
 i8G73fQGiuoYg506vREmfP/QPKzshV3Yiq3KfmwwWT6ORmMSALyv6F1Ff3CiEtpG43SntEgpmUH
 kRh41C8Ztk9UJg0NJSptstjY4CGy40pnsFeBYKpn3k9Q/XxT/muawj5dwSsfCh4wNl28kM0a9Gh
 F+l/wZXMh8lurAEji+cMm3gBa4MaXrcqP4gkuw4ajyEcUYUuXm98XOUtlCuzoiffk9EzygTcp8B
 tuaD3aUh7Y9VuKnfWtqdqe51QqJWDQv4i5RALJjXXlfHJfylw5ZEVJMHmNL4H/XcehbJYXCggXj
 c0DvTyMg41lQzPw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Inspired by Richard's patch set for SDM670, I noticed that SDM845
follows the same pattern. This change prepares for enabling
additional cameras.

These pinctrl settings have been verified against the downstream
SDM845 kernel.

Since most of these are not yet used in mainline, testing was done
on sdm845-next using OnePlus 6 cameras with downstream drivers.

Thank you
David

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Added mclk3. (Vladimir)
- Reword commit messages.
- Corrected commit msg name. (Konrad)
- Link to v1: https://lore.kernel.org/r/20251213-sdm845-mclk-v1-0-197bc947d4c6@ixit.cz

---
David Heidelberg (2):
      arm64: dts: qcom: sdm845: Introduce camera master clock pinctrl
      arm64: dts: qcom: sdm845-db845c: Use pad fn instead of defining own

 .../qcom/sdm845-db845c-navigation-mezzanine.dtso   |  2 +-
 arch/arm64/boot/dts/qcom/sdm845-db845c.dts         | 16 -------
 arch/arm64/boot/dts/qcom/sdm845.dtsi               | 56 ++++++++++++++++++++++
 3 files changed, 57 insertions(+), 17 deletions(-)
---
base-commit: 12b95d29eb979e5c4f4f31bb05817bc935c52050
change-id: 20251213-sdm845-mclk-041f2a952e31

Best regards,
-- 
David Heidelberg <david@ixit.cz>

