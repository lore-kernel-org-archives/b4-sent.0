From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/3] Regulator adjustments for OnePlus 6 and 6T
Date: Tue, 18 Nov 2025 15:52:24 +0100
Message-Id: <20251118-dts-oneplus-regulators-v2-0-3e67cea1e4e7@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACiIHGkC/4WNQQqDMBBFryKz7pQkIk276j2Ki6gTHZAoGRVby
 d2beoEu3+f/9w8QikwCj+KASBsLTyGDuRTQDi70hNxlBqNMpbW22C2CU6B5XAUj9evolikKKuu
 cs5VvXWkhj+dInvdT/KozDyy59z5/Nv1L/yo3jQpvd98Yr7ypyubJOy/X9gN1SukLbIBILroAA
 AA=
X-Change-ID: 20251118-dts-oneplus-regulators-08aaa85fca38
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=990; i=david@ixit.cz;
 h=from:subject:message-id; bh=mSOyn6fDaIUa/uROigj1akZ2xqYPmv8o0/RUvLGCbb0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHIgrWUmZancU3qRBcKEMRSOrbh7vx+YhDN+X2
 Hmf0l/mX2SJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRyIKwAKCRBgAj/E00kg
 cpskEADNBFNDvXehkx8jA6ZdvRz45wiN94bJ2q4PtYiHSQCz8l7meHQoaHBfk3ecXqk/m53r4hy
 wuS5fPIkA7ANsp7NopvkXaPhWj+sjPol/W6rIy1fkAIq2KiVQsZq4oYLFp4yky9QtFbT2quoZY7
 by5IYyJB6U4/h96Y44RqLZMAoZz6KVyHCJtn+28YSte8ed3rK6dacWsra5SlhVXjswBMfL8RkBk
 rY9kxAbWP6M25hclynVOC7voX4kiSPHUuBTxp9FntIwrpjWBYoMf8J5gNJb03CZqPeT9FSn4Tct
 7oIA7i728EoIlBiAhKYPna0A93FwPrgwk+FgZggxEyEPG4+ZAfxd1U0A7j8cWyNXRmpG+BLOdhI
 5yTt3e5UPROcL7nkHPQM5xj4sDhAkpi6qUq4HeOwT8hEJhifm+TDlTTM95iQ8p3uAn2Ga6Cz82Q
 tQ5ZVAqinl6s7XGImXoUnu79YkWDCkRsc3u5LdkNzCYguwYW7WSaTe8oCmYv6gRKZyCtL9A43fx
 46UkjDyQ0OE/PIhwtBtsfdEsKHQF0Daa8fy/9lbrLNcap74dg5QTHhG0oTxrfRVhrmv62C0+uir
 i9iBlUr1j3sOLCq8ZSKB8igQXh4uffi/5Cshg3+73+1lqcKhpMtlbLsys1dA7i5oDBzup56kN2M
 PXepJM54Hm6sAPg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Small regulators adjustments, tested on sdm845-mainline and sdm845-next
tree with recently fixed (6) and upstreamed (6T) drivers.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Corrected description of
  "arm64: dts: qcom: sdm845-oneplus: Don't mark ts supply boot-on".
  (Konrad)
- Added Fixes tag to the commits. (Konrad)
- Link to v1: https://lore.kernel.org/r/20251118-dts-oneplus-regulators-v1-0-79fb2f0f253b@ixit.cz

---
Casey Connolly (3):
      arm64: dts: qcom: sdm845-oneplus: Don't mark ts supply boot-on
      arm64: dts: qcom: sdm845-oneplus: Don't keep panel regulator always on
      arm64: dts: qcom: sdm845-oneplus: Mark l14a regulator as boot-on

 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)
---
base-commit: 187dac290bfd0741b9d7d5490af825c33fd9baa4
change-id: 20251118-dts-oneplus-regulators-08aaa85fca38

Best regards,
-- 
David Heidelberg <david@ixit.cz>

