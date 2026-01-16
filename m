From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 16 Jan 2026 14:32:21 +0000
Subject: [PATCH v4 2/7] units: Add HZ_PER_GHZ definition
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260116-adf41513-iio-driver-v4-2-dbb7d6782217@analog.com>
References: <20260116-adf41513-iio-driver-v4-0-dbb7d6782217@analog.com>
In-Reply-To: <20260116-adf41513-iio-driver-v4-0-dbb7d6782217@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768573956; l=642;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=Mv2pAN6X4qTIrdTXsQmD4zyISKh5GA9YF7QZeduEWxY=;
 b=eoiVCNbs0HMipw6thyXDkCSXRU2xNbJSDigo82wNn4gzbYFvLGN9+ouOf6BCegC5ITI7OL99m
 EjTsOcYh4InAB0Fwo/0n9j3semAfRo+ZRVFHgJ4xrjtQVVloIWmc7QI
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

New PLL IIO driver supports output frequency of several GHz.
The new define helps to constraint DT properties and frequency
calculation parameters.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 include/linux/units.h | 1 +
 1 file changed, 1 insertion(+)

diff --git a/include/linux/units.h b/include/linux/units.h
index 00e15de33eca..06870e9e90b8 100644
--- a/include/linux/units.h
+++ b/include/linux/units.h
@@ -27,6 +27,7 @@
 
 #define HZ_PER_KHZ		1000UL
 #define HZ_PER_MHZ		1000000UL
+#define HZ_PER_GHZ		1000000000UL
 
 #define KHZ_PER_MHZ		1000UL
 #define KHZ_PER_GHZ		1000000UL

-- 
2.43.0

