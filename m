From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/4] sdm845: Update firmware paths
Date: Mon, 22 Dec 2025 20:05:36 +0100
Message-Id: <20251222-oneplus6-new-fw-path-v1-0-a2d366f9eb89@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAICWSWkC/x3MSwqAMAwA0atI1gY0VK1eRVwUTTUgtbT+QLy7x
 eVbzDwQOQhH6LIHAp8SZXMJZZ7BuBg3M8qUDFRQVRIRbo79esQaHV9oL/RmX7DQxqpGaV1PLaT
 UB7Zy/9t+eN8PVDmVZGYAAAA=
X-Change-ID: 20251222-oneplus6-new-fw-path-08af474886d9
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1126; i=david@ixit.cz;
 h=from:subject:message-id; bh=XAzRaUtpQSpLF7PqIZuIw0FO0Ql8emL2AC23FHRYVkE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpSZaD/d5ILSKZpSBgn8hdmX66LHDjB8DsyxS6i
 D/XcqLSF9KJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaUmWgwAKCRBgAj/E00kg
 cr2rD/9f5JFbgw9MRTNdc6sP8huUcSldBiTAte5Ee6T6fZbDdF0qKB99JHGobo+CqFANnLXkxkF
 s/mWvHXv2zBolyI52noFn3L82yNMvEUx77lzuItyCJub/fQScKm4WxBLVsrjxiFa0lsT0zeFEYd
 GT23gilHIqOWrN4tqIn1MDpbSsWBwkTTupV4krIDrur3+dt4K3KN/HggHQDe8OfyxkNXiutMcPD
 y4ku18TUmBB28T2Ji/QpfJNSb4ho3N7IsCnI3taC+7dcEvbeRVAse+d1/zd7IVC39O0q/kMsBts
 oJplE4EzxNo9Yq6KSOPkG+BOtc5EHBirxgeZH0rNy46Z5mKHbFCi0Ed8ov/g7569smpiLqRXwPO
 E5d0aoI40rIZi13HiZM4CSIQgAK8AZ4kSbsB767GPJiuC+myYomp/swI4/MPC6dfBRZtbprEqn0
 8VovEDM3jhCPtOkNiIh5X2kWtvDThIip/Orxv4cyZlUZNkViyEiW4PSxfdaqbZfZW9QrsuG+JYy
 MpULAFt7Am6/mP+lOwSzMTmCpcqXZV/81ouvEwYeecBdM7ykO7UffOj8gSo4f+nkE7NRRuh/NGq
 xhyuEG+JjliATninJ6JpdOVuCl5OCMn2CiLMShzNoEtPGVurZLi3QgFUGEHL+A9m9OWaw+1EWq9
 oOh6msndLaJwSZw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the paths for phones, where there are no patches pending which
includes the firmware path update.

I haven't touched the sdm845-mtp and db845c intentionally.

After merging, I'll notify distros and send MR against droid-juicer.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (4):
      arm64: dts: qcom: sdm845-oneplus: Update firmware paths
      arm64: dts: qcom: sdm845-axolotl: Update firmware paths
      arm64: dts: qcom: sdm845-samsung-starqltechn: Update firmware paths
      arm64: dts: qcom: sdm845-xiaomi-polaris: Update firmware paths

 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 23 ++++++++++++++--------
 .../boot/dts/qcom/sdm845-samsung-starqltechn.dts   | 15 ++++++++------
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts  | 22 +++++++++++++--------
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts | 17 ++++++++++------
 4 files changed, 49 insertions(+), 28 deletions(-)
---
base-commit: cc3aa43b44bdb43dfbac0fcb51c56594a11338a8
change-id: 20251222-oneplus6-new-fw-path-08af474886d9

Best regards,
-- 
David Heidelberg <david@ixit.cz>

