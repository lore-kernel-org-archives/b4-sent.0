From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/3] Regulator adjustments for OnePlus 6 and 6T
Date: Tue, 18 Nov 2025 15:11:34 +0100
Message-Id: <20251118-dts-oneplus-regulators-v1-0-79fb2f0f253b@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJZ+HGkC/x3MMQqAMAxA0atIZgOtIhSvIg5BowZKK4mKIN7d4
 viG/x8wVmGDvnpA+RKTnAp8XcG0UVoZZS6GxjWd9z7gfBjmxHs8DZXXM9KR1dAFIgrdMlEboMS
 78iL3Px7G9/0AH9nPPmgAAAA=
X-Change-ID: 20251118-dts-oneplus-regulators-08aaa85fca38
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, 
 Casey Connolly <casey.connolly@linaro.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=715; i=david@ixit.cz;
 h=from:subject:message-id; bh=zEEZ+tgbupnE8MuYxfeIaw3voCncjbXCdXviXkL1Ya0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHH6YHpLoRgCilp9CegCwUfGbv+grpz3AFEeEy
 /ZxAj2F4a6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRx+mAAKCRBgAj/E00kg
 ch6aD/492aZ6/9Mu1d9NDkM4vpGB8G9iS/nyBg9g62iLjsvczeZTHNG0jkmYbkhB/4WEA7Nlhot
 AmBXPm3FUBU/6bmlo97+daI6LSzlYzkgsZ+hPKqGGnuZ78jiahA1YjUQuWA7xi1XEY4UgX7ORlY
 XF98Q49LxOjPnvqtHXW3pUu6xsZGU3CMd0s868zFtQOsqpLUX2zJ8zpcw/TvPozx9ex7K65T5GQ
 xElWHn7eqChBF99IIq36G7kBKOufI3sUTx38zvRxkoCCQMkm71cVg9ZVa9WPS8ZkMgwwapp523I
 nrA5CNuuukReulHAIukqbq+gwnK0m2p2VUiwKt63BHjl0jE+qs9r7aWeFLxdEFz5Pp9lAdNp5pr
 EoQ6QNGzt3UICjp3JmUM0VbE6WHV3qbTBO96fok1lNjp2oUyrhi+BmiruXM4Edj3U3xGF9ysrDX
 qvX+sGynJQGlkCpreijK98/pVwoAfha0e7oTV9nDqcwnWQOMEWKxASYvKFezxgWqXUgAcrYp+sb
 bDIcOKlrFgU4jXMsWA9PKdigML04hy6TQfOy4NV0mWA0Srpbxmqdi7o7ObEd+NUsGdm1CVYt1cU
 dLn68SErFLSJ7dwN6KzTKTiVLRuH7NMdqx9Nwvn5a5svep0jkqWLiCYsl3k3XupNUdMVQ2hUle6
 jlKggiTCgm5xwBw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Small regulators adjustments, tested on sdm845-mainline and sdm845-next
tree with recently fixed (6) and upstreamed (6T) drivers.

Signed-off-by: David Heidelberg <david@ixit.cz>
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

