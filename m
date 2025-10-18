From: Maud Spierings <maud_spierings@hotmail.com>
Date: Sat, 18 Oct 2025 11:59:48 +0200
Subject: [PATCH v2 2/2] Documentation: migration-2025.11.0: add note about
 new gpio behaviour
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251018-imx_gpio-v2-2-22e4fc090de6@hotmail.com>
References: <20251018-imx_gpio-v2-0-22e4fc090de6@hotmail.com>
In-Reply-To: <20251018-imx_gpio-v2-0-22e4fc090de6@hotmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760781589; l=841;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=jPNzUK/lQcbfb8T2/TBWUgMNeR+eIZuOIYqxnDE4JG8=;
 b=verRk9OLR3/Kd7bb8TI0goIF1hGWfP9utQPNAtv0ZtJPpSx5x8KH0VddBeNHFIq5rvnbiuona
 Eq6Oo7RFj64AGw98dT3+ornYQwG5iQuYY0QtjWWD1dLp/QFl7fov2jz
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The previous change, changes the behaviour of reading gpio values, make
a note of it in the migration guide.

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
 Documentation/migration-guides/migration-2025.11.0.rst | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/Documentation/migration-guides/migration-2025.11.0.rst b/Documentation/migration-guides/migration-2025.11.0.rst
new file mode 100644
index 0000000000..9cbc46acc3
--- /dev/null
+++ b/Documentation/migration-guides/migration-2025.11.0.rst
@@ -0,0 +1,7 @@
+i.MX GPIOs
+----------
+
+Reading output GPIOs now returns the configured output level instead
+of reading back the input register. This aligns us with what Linux
+is doing, but may falsify readings of single-ended GPIOs that have
+the SION bit configured.

-- 
2.51.1.dirty

