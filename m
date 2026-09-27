From: Haseeb Malik <haseebulhaq55@gmail.com>
Date: Sun, 27 Sep 2026 01:03:24 -0400
Subject: [PATCH net] macsec: check the resolved SCI for duplicates
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260927-fix-macsec-duplicate-sci-v1-1-085bd742c8e9@gmail.com>
X-B4-Tracking: v=1; b=H4sIAJujuGoC/x2MQQ6CQAxFr0K6thGGMEavYliUTpUmMpIpGhPC3
 S0s38v/bwWTomJwq1Yo8lXTd3ZoThXwSPkpqMkZQh1ifQ0RH/rDidiEMX3mlzItgsaKki6x7Yg
 bbjvw+1zEt0f6DlkW6F0OZIJDoczjXnV9nkgzbNsfSsjjKYoAAAA=
To: Sabrina Dubroca <sd@queasysnail.net>, netdev@vger.kernel.org
Cc: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Shuah Khan <shuah@kernel.org>, 
 Hannes Frederic Sowa <hannes@stressinduktion.org>, 
 linux-kselftest@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Haseeb Malik <haseebulhaq55@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790485403; l=4803;
 i=haseebulhaq55@gmail.com; s=default; h=from:subject:message-id;
 bh=N1A+xRNu+DLjB78Ftg6Qjky4tZ5V4x/9AIQd+EByWy8=;
 b=SfylQ/QWPxKVrWMM2Dz8HGEh59uWQPV/8rOawh/xGabZvUfttHm9XqeCzy6YrK5RDZVsvDfjn
 UzY3am7lBi/BgPDDzcNxbQVB8SayP7SlLvl8eN4BLwv0WMcispruubF
X-Developer-Key: i=haseebulhaq55@gmail.com; a=ed25519;
 pk=U/yCVc6cTsqDqxWLzvoONZ7DUA3EfRU+rfO9Xxo4p2w=
X-Endpoint-Received: by B4 Relay for haseebulhaq55@gmail.com/default with auth_id=1026
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An all-ones IFLA_MACSEC_SCI selects the default SCI derived from the
MACsec device's MAC address and port 1. macsec_init_secy() resolves this
value and stores the result in secy.sci, but macsec_newlink() checks for
duplicates using the unchanged local sci argument.

Consequently, an all-ones request can create a second MACsec device with
the same transmit SCI on the same lower device, while requesting that
SCI explicitly returns -EBUSY.

Check the initialized SecY's SCI so that duplicate detection uses the
value that the new device will actually use. Preserve the all-ones
fallback when the resulting SCI is available.

Add regression tests for duplicate rejection using default, explicit and
all-ones SCI requests, and for valid fallback and reuse after deletion.
The same tests reproduce two failures before the fix and pass afterward.

Fixes: c09440f7dcb3 ("macsec: introduce IEEE 802.1AE driver")
Link: https://lists.openwall.net/netdev/2026/09/16/11
Assisted-by: LLM
Signed-off-by: Haseeb Malik <haseebulhaq55@gmail.com>
---
Tested on arm64/virtme with KASAN and lockdep: the new regression
tests go from 5 pass/2 fail to 7 pass/0 fail. The full MACsec selftest
passes all 15 cases without skips.
---
 drivers/net/macsec.c                          |  2 +-
 tools/testing/selftests/drivers/net/macsec.py | 48 +++++++++++++++++++++++++++
 2 files changed, 49 insertions(+), 1 deletion(-)

diff --git a/drivers/net/macsec.c b/drivers/net/macsec.c
index 78a19b134632..7dabdac754f1 100644
--- a/drivers/net/macsec.c
+++ b/drivers/net/macsec.c
@@ -4254,7 +4254,7 @@ static int macsec_newlink(struct net_device *dev,
 	if (err < 0)
 		goto unregister;
 
-	if (rx_handler && sci_exists(real_dev, sci)) {
+	if (rx_handler && sci_exists(real_dev, macsec->secy.sci)) {
 		err = -EBUSY;
 		goto unlink;
 	}
diff --git a/tools/testing/selftests/drivers/net/macsec.py b/tools/testing/selftests/drivers/net/macsec.py
index 9a83d9542e04..72ee1c6e146e 100755
--- a/tools/testing/selftests/drivers/net/macsec.py
+++ b/tools/testing/selftests/drivers/net/macsec.py
@@ -263,6 +263,52 @@ def test_offload_state(cfg) -> None:
             "features should match first offload-on snapshot")
 
 
+@ksft_variants([
+    KsftNamedVariant("default", "", ""),
+    KsftNamedVariant("explicit", "", "sci {sci}"),
+    KsftNamedVariant("undefined", "", "sci ffffffffffffffff"),
+    KsftNamedVariant("undefined_default", "sci ffffffffffffffff", ""),
+    KsftNamedVariant("undefined_explicit", "sci ffffffffffffffff", "sci {sci}"),
+    KsftNamedVariant("undefined_twice", "sci ffffffffffffffff",
+                     "sci ffffffffffffffff"),
+])
+def test_duplicate_sci(cfg, first, second) -> None:
+    """Reject duplicate transmit SCIs, including the undefined-SCI fallback."""
+
+    ms0 = _macsec_name(0)
+    ms1 = _macsec_name(1)
+    sci = _get_mac(cfg.ifname).replace(":", "") + "0001"
+
+    ip(f"link add link {cfg.ifname} {ms0} type macsec {first}")
+    defer(ip, f"link del {ms0}")
+    with ksft_raises(CmdExitFailure):
+        ip(f"link add link {cfg.ifname} {ms1} type macsec "
+           f"{second.format(sci=sci)}")
+        # Clean up if the kernel incorrectly accepted the duplicate.
+        defer(ip, f"link del {ms1}")
+
+
+def test_undefined_sci(cfg) -> None:
+    """An undefined SCI still selects the default when it is available."""
+
+    ms0 = _macsec_name(0)
+    ms1 = _macsec_name(1)
+    sci = _get_mac(cfg.ifname).replace(":", "") + "0001"
+
+    # A different port on the same lower device must not block the fallback.
+    ip(f"link add link {cfg.ifname} {ms0} type macsec port 2")
+    defer(ip, f"link del {ms0}")
+    ip(f"link add link {cfg.ifname} {ms1} type macsec sci ffffffffffffffff")
+    cleanup = defer(ip, f"link del {ms1}")
+    info = ip(f"-d link show dev {ms1}", json=True)[0]
+    ksft_eq(info["linkinfo"]["info_data"]["sci"], sci)
+
+    # Deleting a device must make its SCI available again.
+    cleanup.exec()
+    ip(f"link add link {cfg.ifname} {ms1} type macsec sci ffffffffffffffff")
+    defer(ip, f"link del {ms1}")
+
+
 def _check_nsim_vid(cfg, vid, expected) -> None:
     """Checks if a VLAN is present. Only works on netdevsim."""
 
@@ -333,6 +379,8 @@ def main() -> None:
                   test_max_secy,
                   test_max_sc,
                   test_offload_state,
+                  test_duplicate_sci,
+                  test_undefined_sci,
                   test_vlan,
                   test_vlan_toggle,
                   ], args=(cfg,))

---
base-commit: 11536ee3d3e0b1bd35b6f3f8df55a6053eb0c71d
change-id: 20260926-fix-macsec-duplicate-sci-ed7635ac1c35

Best regards,
-- 
Haseeb Malik <haseebulhaq55@gmail.com>

