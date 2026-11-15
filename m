From: Alexey Skidanov <alexeys@xsightlabs.com>
Date: Sun, 15 Nov 2026 15:03:29 +0200
Subject: [PATCH net] selftests: drv-net: psp: skip unsupported versions in
 netkit data test
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-main-v1-1-7011cd84e54a@xsightlabs.com>
X-B4-Tracking: v=1; b=H4sIAKCt+WoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0NT3dzEzDxdgyRj87SkVNNUwxQjJaDSgqLUtMwKsDHRSnmpJUqxtbU
 AdT6qw1sAAAA=
X-Change-ID: 20261115-main-0b37fbe5e1d2
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Shuah Khan <shuah@kernel.org>, Wei Wang <weiwan@google.com>
Cc: netdev@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, guyt@xsightlabs.com, 
 Alexey Skidanov <alexeys@xsightlabs.com>, 
 Lior Yizchak <liory@xsightlabs.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794747829; l=1543;
 i=alexeys@xsightlabs.com; s=20261115; h=from:subject:message-id;
 bh=+HHsLPET6WB6VgqdrP9TIelZlMYJuT8XLUrUt8UuqfA=;
 b=vVXw9si6EHE39Eo2dXea6LyskLSwuKQn3lHCXtuRRoLGUziB4aoRDjPgOp+NV7p3TzDUs3tu5
 g/A3NOSYmkgD2g/WBTPcfCZDxW5rub9IeXDMvfNx86udW9Ok7PKo00K
X-Developer-Key: i=alexeys@xsightlabs.com; a=ed25519;
 pk=ve3muo5qeQ0fgK78LFE9NWqGShBLIHZrMBKOM0exhfY=
X-Endpoint-Received: by B4 Relay for alexeys@xsightlabs.com/20261115 with auth_id=1532
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

data_basic_send_netkit_psp_assoc() runs for PSP versions 0-3. The
non-netkit data path already skips versions the device does not
advertise in psp-versions-cap. The netkit path does not, so those
cases fail instead of skipping.

Version 0 stays mandatory. Skip an unadvertised version before opening
the PSP connection.

Fixes: 43cf629700fa ("selftests/net: psp: add dev-assoc data path test")
Signed-off-by: Alexey Skidanov <alexeys@xsightlabs.com>
Signed-off-by: Lior Yizchak <liory@xsightlabs.com>
---
 tools/testing/selftests/drivers/net/psp.py | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/tools/testing/selftests/drivers/net/psp.py b/tools/testing/selftests/drivers/net/psp.py
index c114d2245135..7c8fb2200b39 100755
--- a/tools/testing/selftests/drivers/net/psp.py
+++ b/tools/testing/selftests/drivers/net/psp.py
@@ -728,6 +728,12 @@ def _data_basic_send_netkit_psp_assoc(cfg, version, ipver):
     """
     _assoc_nk_guest(cfg)
 
+    # Version 0 is required by spec, don't let it skip
+    if version:
+        name = cfg.pspnl.consts["version"].entries_by_val[version].name
+        if name not in cfg.psp_info['psp-versions-cap']:
+            raise KsftSkipEx("PSP version not supported", name)
+
     # Enter guest namespace (netns) to run PSP test
     with NetNSEnter(cfg.netns.name):
         cfg.pspnl = PSPFamily()

---
base-commit: aa40afa831ebfe45e40a23721711059f2ac584d4
change-id: 20261115-main-0b37fbe5e1d2

Best regards,
-- 
Alexey Skidanov <alexeys@xsightlabs.com>

