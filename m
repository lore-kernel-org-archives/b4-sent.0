From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 0/3] Add modemsmem for Google phones
Date: Mon, 16 Nov 2026 16:50:42 +0100
Message-Id: <20261116-modemsmem-v3-0-24ebc7ed6eb9@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WOyw6CMBBFf4XM2po+eIgr/8O4gDLImBRIiw1K+
 HdbXOhClye558ws4NASOjgmC1j05GjoA6hdArqr+isyagKD5DLnJc+ZGRo0zqBhZSUaLXjB26K
 GsB8ttjRvrfPlze5e31BPMRAXHblpsI/tmBdx96vrBeOsUrlK6yxTh1ScaKZpr58Qq17+9WTwv
 p/6eOu6vgCnQOQT6gAAAA==
X-Change-ID: 20260906-modemsmem-9a1dc1070f7b
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Sibi Sankar <sibi.sankar@oss.qualcomm.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Miro Mraz <mraz.miro@seznam.cz>
Cc: Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 linux-remoteproc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1641; i=david@ixit.cz;
 h=from:subject:message-id; bh=DdaxKAZ4pdHBSajOP2q91sjAXPyTMnm5rH95OLafWRI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq+yZeP42NQmDeI/FFrlkfauje6HKyxzmxLG95l
 VDhrnJJLAyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCavsmXgAKCRBgAj/E00kg
 ciSgEACuAx5BfkA0+fpOXO2lxUj8e6wt5O3Q+0aOZcwR9SeAjX/bKm7P/xxyW5cmKafQyItJt35
 h4YUEIPNMvAsgC5Ab8mY1sVyBHvuHbbPa8WSiP+/r0eznxwX2AyPK9CrqoJIrcqIUBZVxFecdk6
 6cguaWrPUv3NQPTqYLkunb/1wP2XosF4d6oSIkBzo3MW4p4SGE2CKOgQZBO9mpynX94B+jEUH8w
 yTZjCbYow4YF38eW7/3+dQNlz9k0p1iSqhdcemwgn2/BrkO2G2MGKj4W61tpnb+GfLP61UZM4ex
 2bdyc9gnJIfeL/2USoyaYP3pYIw2M09D50VcAlDMNtOB5vUfvOZJm+Uh9NfR9TNk0tkeH0ohNfl
 RZtWER6EB9ZrfdElsoBpXJC+q9WsqFmodZXMK2i3AsWMwpmDrXmevFwqpeIgI/3s6LVhJf48G8i
 i0ObwMTdQxa9BligbhTzP+7xVCAGUBeB9dYYFZd2S9Pnobxq7hzioImkdDUBonzyJn+44oHJJ0x
 UOXohdq57WJAa2mpW2euyGU66VNrkxjT1UVfju36Wb642OIVlg2wWHTYbSlTWo/SeuBGAMCi7Rj
 yFm76Ub74ovUr2cIGspgv3Cqb0sgFOvy+EjE0g5LV5sBqh0JpBfFuexE7SIgUyXhdZjenaof6/s
 2FASUPL4KlzrIEw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The modem on the Pixel 3 family will not come up without the SoC
information Google's downstream kernel publishes in SMEM item 134.
This is the upstream version, modelled per review feedback as a
property of the modem remoteproc node rather than a standalone node
and driver.

This replaces the standalone drivers/soc/qcom/modemsmem driver from
the previous revision: per review feedback the requirement is better
modelled as a property of the modem remoteproc node, with the
conditional snippet in the remoteproc driver.

Changes in v2:
- Represent the requirement as a "google,require-socinfo" property on
  the MSS remoteproc node instead of a standalone node and driver.
  (Bjorn)
- Move the SMEM publish code into the qcom_q6v5_mss remoteproc driver,
  gated by the property. (Bjorn)
- Hard-code SMEM item id 134, no qcom,smem-id property. (Bjorn, Konrad)
- Drop the RFC prefix.
- Link to v1: https://patch.msgid.link/20260906-modemsmem-v1-0-a3634b553841@ixit.cz
    

---
David Heidelberg (3):
      dt-bindings: remoteproc: qcom,msm8996-mss-pil: Document google,require-socinfo
      remoteproc: qcom_q6v5_mss: Publish socinfo for Pixel modems
      arm64: dts: qcom: sdm845-google: Require modem socinfo

 .../bindings/remoteproc/qcom,msm8996-mss-pil.yaml  |  9 +++
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi |  2 +
 drivers/remoteproc/qcom_q6v5_mss.c                 | 75 ++++++++++++++++++++++
 3 files changed, 86 insertions(+)
---
base-commit: aaa2f954c21b205a0bcd0961e5b2be4e82e58455
change-id: 20260906-modemsmem-9a1dc1070f7b

Best regards,
--  
David Heidelberg <david@ixit.cz>

