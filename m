From: Sven Peter <sven@kernel.org>
Subject: [PATCH 0/3] arm64: dts: apple: Fix cpus node indentation
Date: Sun, 30 Aug 2026 16:22:06 +0200
Message-Id: <20260830-b4-apple-dts-fixes-v1-0-cc20f8445754@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM0Q5EMBCF4VeRud5JqgTdV9m4aBmMCE0HkYh3V
 +vyy8l/ThAKTALf5IRAOwsvc0T6SaAZ7NwTchsNWulCVZlCl6P1fiJsV8GODxLUrjS5sanVnYE
 Y+kD/IXa/+rVsbqRmfZ7gum4zGuGsdgAAAA==
X-Change-ID: 20260830-b4-apple-dts-fixes-2b7949a1a2f9
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=735; i=sven@kernel.org;
 h=from:subject:message-id; bh=M157gAg3aXNBMLpJR2h8e9GqFXRRpGln0DE/YBYm+4E=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9YUmzmcy1WeiCR9Kd5qVp2tkdp03Y1H9GuC1A0VhwVMB
 VttFU51lLIwiHExyIopsmzfb2/65OEbwaWbLr2HmcPKBDKEgYtTACay4Asjw0OectuLx0SFxBd8
 vDSHQ7So7qqhd3jS+rdH8xrfhD3tPsrI8N6ZSSzsB5O+nn3ex+0LgmaVri0QS9oos3DNw//XtrX
 78gEA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

Just a small series to drop a spurious space in our dts file. No
functional changes.

Best,

Sven

Signed-off-by: Sven Peter <sven@kernel.org>
---
Sven Peter (3):
      arm64: dts: apple: t602x: Fix cpus node indentation
      arm64: dts: apple: t6030: Fix cpus node indentation
      arm64: dts: apple: t6032: Fix cpus node indentation

 arch/arm64/boot/dts/apple/t602x-common.dtsi | 2 +-
 arch/arm64/boot/dts/apple/t6030.dtsi        | 2 +-
 arch/arm64/boot/dts/apple/t6032.dtsi        | 2 +-
 3 files changed, 3 insertions(+), 3 deletions(-)
---
base-commit: 08dbfad3f5040f5bdb6c529da20d6d4e81fefd72
change-id: 20260830-b4-apple-dts-fixes-2b7949a1a2f9

Best regards,
--  
Sven Peter <sven@kernel.org>

