From: Esteban Urrutia <esteuwu@proton.me>
Date: Fri, 31 Jul 2026 01:00:09 -0400
Subject: [PATCH v2 2/2] usb: typec: ucsi: ucsi_glink: Add compatible string
 for SM8475
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-sm8475-pmic-glink-v2-2-28c04928ef22@proton.me>
References: <20260731-sm8475-pmic-glink-v2-0-28c04928ef22@proton.me>
In-Reply-To: <20260731-sm8475-pmic-glink-v2-0-28c04928ef22@proton.me>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-usb@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785474171; l=998;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=sd0MJRnY8fTZ1DfMoMimnK+7cETQL/NR6zUIxPB5jeQ=;
 b=eDroRVFNMFxKPR7g4qEz2Y1nWeGk7HqbWZeV5YABNGgp3y7DOBqhaOAgESwYdMYe4fQ0g+Crw
 l9i80FsgchHBrCwtmU6v1LYJm7vYasjukUYLFLWtXhjPp/wpXSuz4F8
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible string for the PMIC GLINK service running on the coprocessor
found in the SM8475 SoC.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 drivers/usb/typec/ucsi/ucsi_glink.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/usb/typec/ucsi/ucsi_glink.c b/drivers/usb/typec/ucsi/ucsi_glink.c
index 12e07b9fe622..78a0ea349ed4 100644
--- a/drivers/usb/typec/ucsi/ucsi_glink.c
+++ b/drivers/usb/typec/ucsi/ucsi_glink.c
@@ -381,6 +381,7 @@ static const struct of_device_id pmic_glink_ucsi_of_quirks[] = {
 	{ .compatible = "qcom,sc8280xp-pmic-glink", .data = &quirk_sc8280xp, },
 	{ .compatible = "qcom,sm8350-pmic-glink", .data = &quirk_sc8180x, },
 	{ .compatible = "qcom,sm8450-pmic-glink", .data = &quirk_sm8450, },
+	{ .compatible = "qcom,sm8475-pmic-glink", .data = &quirk_sm8450, },
 	{ .compatible = "qcom,sm8550-pmic-glink", .data = &quirk_sm8450, },
 	{ .compatible = "qcom,x1e80100-pmic-glink", .data = &quirk_x1e80100, },
 	{}

-- 
2.55.0

