From: Jack Cheng <Cheng.JackHY@inventec.com>
Date: Tue, 01 Jul 2025 12:03:45 +0000
Subject: [PATCH 1/2] dt-bindings: trivial: Add q50sn12072 and q54sj108a1
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250701-add-support-for-q50sn12072-and-q54sn120a1-v1-1-c387baf928cb@inventec.com>
References: <20250701-add-support-for-q50sn12072-and-q54sn120a1-v1-0-c387baf928cb@inventec.com>
In-Reply-To: <20250701-add-support-for-q50sn12072-and-q54sn120a1-v1-0-c387baf928cb@inventec.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, Jack Cheng <Cheng.JackHY@inventec.com>, 
 Jack Cheng <cheng.jackhy@inventec.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751371491; l=1103;
 i=Cheng.JackHY@inventec.com; s=20250701; h=from:subject:message-id;
 bh=iMAIxaFU1vJJldUQGTtol5eSWpPkR5/YqPptwSKn8kY=;
 b=+nLfOUtuC/vAC7V1DydaU6IRZa01xhp3nYid+nup9vz3j5XIxoeil/eamWmynC+WKvwxfX4g/
 3hTCxrTpXX4B7/LhG3NlV/7uDxCjM7MMXn26cUhKGhf/+/E9n6yMtlL
X-Developer-Key: i=Cheng.JackHY@inventec.com; a=ed25519;
 pk=L+GNI15NJXj7JAu9YqFXp9hL3rwZWbBbjlEeDjPvm68=
X-Endpoint-Received: by B4 Relay for Cheng.JackHY@inventec.com/20250701 with auth_id=449
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Jack Cheng <cheng.jackhy@inventec.com>

Add support for the Delta Electronics q50sn12072 and q54sj108a1
1/4 Brick DC/DC Regulated Power Modules.

Signed-off-by: Jack Cheng <cheng.jackhy@inventec.com>
---
 Documentation/devicetree/bindings/trivial-devices.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/trivial-devices.yaml b/Documentation/devicetree/bindings/trivial-devices.yaml
index 27930708ccd5..dfcdf0c4aca3 100644
--- a/Documentation/devicetree/bindings/trivial-devices.yaml
+++ b/Documentation/devicetree/bindings/trivial-devices.yaml
@@ -78,7 +78,11 @@ properties:
             # Delta Electronics DPS920AB 920W 54V Power Supply
           - delta,dps920ab
             # 1/4 Brick DC/DC Regulated Power Module
+          - delta,q50sn12072
+            # 1/4 Brick DC/DC Regulated Power Module
           - delta,q54sj108a2
+            # 1/4 Brick DC/DC Regulated Power Module
+          - delta,q54sn120a1
             # Devantech SRF02 ultrasonic ranger in I2C mode
           - devantech,srf02
             # Devantech SRF08 ultrasonic ranger

-- 
2.43.0

