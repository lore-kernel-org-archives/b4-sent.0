From: Daniel Svendsen <das@emlogic.no>
Date: Thu, 26 Nov 2026 01:15:35 +0100
Subject: [PATCH] eeprom: at24: wait for write cycle before releasing
 runtime PM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-at24-write-cycle-v1-1-ec9c38617130@emlogic.no>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/yXMywrCMBBG4Vcps3YgGaRSX0Vc1MkfO6VUSVIvl
 L67UZff4pyVMpIh07FZKeFh2W5zhd81pEM/X8EWqkmctN5Ly32RPT+TFbC+dQIfFCEG52IXhWp
 2T4j2+i1P57/zchmh5fuhbfsATyB/BHQAAAA=
X-Change-ID: 20261126-at24-write-cycle-7cedfd00f9f2
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Srinivas Kandagatla <srini@kernel.org>
Cc: Bibby Hsieh <bibby.hsieh@mediatek.com>, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Daniel Svendsen <das@emlogic.no>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795652175; l=2263;
 i=das@emlogic.no; s=20261125; h=from:subject:message-id;
 bh=jcPKGomz5djCGzdGpnaBBVY00UgyabG9Lq9DL7YvIlg=;
 b=E0uKLD3Ha7ZC/+CmF60IMx8YtdMMTlBT+Z0LdwwmzzUaMLHHRKShaDzMFiZH2ZMzteyt+Mnt7
 tvOEjBbvdT8A+yQ/gbUwxly6jwSCdkNSFrBYosuU79fgK4RlWNenY5u
X-Developer-Key: i=das@emlogic.no; a=ed25519;
 pk=NOuNK5ezs2CmhXHDzJ0VumKw5T6c3m0ayEJIk/HKbyA=
X-Endpoint-Received: by B4 Relay for das@emlogic.no/20261125 with auth_id=1644
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

at24_regmap_write() returns as soon as the chip has ACKed the
transfer, but the EEPROM only programs the data afterwards, during its
internal write cycle (typically up to 5 ms). For all but the last
chunk, the following write is NACKed and retried until that cycle has
finished. After the last chunk nothing waits, and at24_write() drops
its runtime PM reference right away. When vcc is controlled through
runtime PM and has no other users, at24_suspend() disables the
regulator in the middle of the write cycle and the last chunk is lost,
while the write is reported as successful.

This was seen on a board where the EEPROM supply is a switchable
regulator used only by at24: 32-byte writes with a 16-byte page size
programmed just the first 16 bytes.

Wait for the write cycle to finish before releasing runtime PM by
doing a one-byte read of the last written address. at24_regmap_read()
retries while the chip NACKs, up to write_timeout.

Fixes: cd5676db0574 ("misc: eeprom: at24: support pm_runtime control")
Cc: stable@vger.kernel.org
Signed-off-by: Daniel Svendsen <das@emlogic.no>
---
 drivers/nvmem/at24.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/nvmem/at24.c b/drivers/nvmem/at24.c
index b9db13cc3e33..03cd83e5caff 100644
--- a/drivers/nvmem/at24.c
+++ b/drivers/nvmem/at24.c
@@ -482,6 +482,7 @@ static int at24_write(void *priv, unsigned int off, void *val, size_t count)
 	struct at24_data *at24;
 	struct device *dev;
 	char *buf = val;
+	char dummy;
 	int ret;
 
 	at24 = priv;
@@ -514,11 +515,17 @@ static int at24_write(void *priv, unsigned int off, void *val, size_t count)
 		count -= ret;
 	}
 
+	/*
+	 * Wait for the last chunk's internal write cycle to finish before
+	 * dropping the runtime PM reference, which may switch off vcc.
+	 */
+	ret = at24_regmap_read(at24, &dummy, off - 1, 1);
+
 	mutex_unlock(&at24->lock);
 
 	pm_runtime_put(dev);
 
-	return 0;
+	return ret < 0 ? ret : 0;
 }
 
 static int at24_make_dummy_client(struct at24_data *at24, unsigned int index,

---
base-commit: ebb7a8dc1e74c705daffe11c2faf38ec2628f838
change-id: 20261126-at24-write-cycle-7cedfd00f9f2

Best regards,
--  
Daniel Svendsen <das@emlogic.no>

