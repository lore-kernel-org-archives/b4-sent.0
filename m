From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Wed, 04 Mar 2026 10:17:47 +0000
Subject: [PATCH 1/2] docs: hwmon: ltc4282: Fix scanned addresses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260304-hwmon-ltc4282-minor-improvs-v1-1-344622924d3a@analog.com>
References: <20260304-hwmon-ltc4282-minor-improvs-v1-0-344622924d3a@analog.com>
In-Reply-To: <20260304-hwmon-ltc4282-minor-improvs-v1-0-344622924d3a@analog.com>
To: linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772619475; l=801;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=jPyppxlzp7XoW4MdpRfX3YQFjkyTPLdNWTIArrDAgW0=;
 b=kCK8mYK8XLjBzElvpm6ulRJxAJbqS//Q/YpKqLgnCvCSz7tXyxAYu1cKIaPlYIV63WuBZdAgV
 2lJSF9c4ud8Ax6r79FgR/7rjopOsH6VMcaLk/ZXHdCiRUvVUzyak8l8
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LTC4282 driver does not implement an I2C .detect() callback, meaning no
I2C address scanning is performed. Update the documentation to
reflect this by replacing the listed I2C address ranges with "-".

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 Documentation/hwmon/ltc4282.rst | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/Documentation/hwmon/ltc4282.rst b/Documentation/hwmon/ltc4282.rst
index a87ec3564998..dd730207b141 100644
--- a/Documentation/hwmon/ltc4282.rst
+++ b/Documentation/hwmon/ltc4282.rst
@@ -9,8 +9,7 @@ Supported chips:
 
     Prefix: 'ltc4282'
 
-    Addresses scanned: - I2C 0x40 - 0x5A (7-bit)
-    Addresses scanned: - I2C 0x80 - 0xB4 with a step of 2 (8-bit)
+    Addresses scanned: -
 
     Datasheet:
 

-- 
2.53.0

