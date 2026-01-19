From: Petr Hodina <petr.hodina@protonmail.com>
Subject: [PATCH 0/2] Enable uart and bluetooth for Xperia devices
Date: Mon, 19 Jan 2026 12:58:51 +0100
Message-Id: <20260119-akatsuki-uart-v1-0-238f4da4fa56@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHscbmkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDI0Nz3cTsxJLi0uxM3dLEohJdkxRzA1NzCzOTpERzJaCegqLUtMwKsHn
 RsbW1ABTPxgNfAAAA
X-Change-ID: 20251217-akatsuki-uart-4d7057864ba7
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Heidelberg <david@ixit.cz>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768823932; l=690;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=HBg6SibUs1urS8KtNtxZyU66tOskoFp3/RfnmX6QDIU=;
 b=Ejt1k5CivNj7Up8XdDKPDpQGKTc6/tLJZt5xAICmDn5470akPSg7HE5f7KO/OLqTy36FOaLC0
 D1WMiVGr21SCiFBSfLTw1S/Omi8TqTbJN3sV98lhdKhgi8S7CgB8ikU
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This fixes the uart instances defined in the dts so the serial
console will now work if uart is attached to Rx pin on the uSD pinout.
Also now enables bluetooth.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Petr Hodina (2):
      arm64: dts: qcom: sdm845-sony-xperia-tama: Correct uart instances
      arm64: dts: qcom: sdm845-sony-xperia-tama: Add bluetooth

 .../boot/dts/qcom/sdm845-sony-xperia-tama.dtsi      | 21 +++++++++++++++++++--
 1 file changed, 19 insertions(+), 2 deletions(-)
---
base-commit: f417b7ffcbef7d76b0d8860518f50dae0e7e5eda
change-id: 20251217-akatsuki-uart-4d7057864ba7

Best regards,
-- 
Petr Hodina <petr.hodina@protonmail.com>

