From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 22 Apr 2026 15:45:35 +0100
Subject: [PATCH 01/22] dt-bindings: iio: dac: ad5696: extend device support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-ad5313r-iio-support-v1-1-ed7dca001d1b@analog.com>
References: <20260422-ad5313r-iio-support-v1-0-ed7dca001d1b@analog.com>
In-Reply-To: <20260422-ad5313r-iio-support-v1-0-ed7dca001d1b@analog.com>
To: Jonathan Cameron <jic23@kernel.org>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Michael Auchter <michael.auchter@ni.com>, linux-hardening@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776869181; l=1192;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=El1N/55Vq+qsAn09ahJqnZZZn0tChOeJyXjS3wCOfPE=;
 b=TqIPGOd3GrgXveavFWj7EsXu+bwU+jXRUWXdLzoMfkv5QNMfFP/RyLpWWDPK69vcKt5oxlaMd
 TJ0F1yb86WPCVgYe+iZgoginWn4D0G+/X7jUkDBMvIjVPbbiV6PPja8
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support for AD5316R, AD5673R, AD5675, AD5677R and AD5697R missing from the
device-tree bindings documentation. These devices have different bit
resolutions or different number of channels so no fallback compatibles
are used.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml b/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml
index b5a88b03dc2f..ed79323bfc93 100644
--- a/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml
+++ b/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml
@@ -16,10 +16,14 @@ properties:
   compatible:
     enum:
       - adi,ad5311r
+      - adi,ad5316r
       - adi,ad5337r
       - adi,ad5338r
       - adi,ad5671r
+      - adi,ad5673r
+      - adi,ad5675
       - adi,ad5675r
+      - adi,ad5677r
       - adi,ad5691r
       - adi,ad5692r
       - adi,ad5693
@@ -29,6 +33,7 @@ properties:
       - adi,ad5695r
       - adi,ad5696
       - adi,ad5696r
+      - adi,ad5697r
 
   reg:
     maxItems: 1

-- 
2.43.0

