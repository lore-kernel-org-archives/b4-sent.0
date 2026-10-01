From: Haseeb Malik <haseebulhaq55@gmail.com>
Date: Thu, 01 Oct 2026 16:40:18 -0400
Subject: [PATCH net v2] macsec: check the resolved SCI for duplicates
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261001-fix-macsec-duplicate-sci-v2-1-330311abe5ec@gmail.com>
X-B4-Tracking: v=1; b=H4sIADHFvmoC/3WOzQ6CMBCEX4Xs2VVa5M+T72E4lGWFTaCQFomG8
 O4W4tXjTGa+mRU8O2EPt2gFx4t4GW0Q+hQBdca2jNIEDTrWWVzqDJ/yxsGQZ8LmNfVCZmb0JMh
 NniWpIUVJCqE+OQ7ZA/0AyzNUwayNZ6ydsdTt1GBfBiN2z3fi59F9jieLOlq/0fz/6KJQYVykd
 ZNfNRVc3tvA6880DlBt2/YFnlctB+AAAAA=
To: Sabrina Dubroca <sd@queasysnail.net>, netdev@vger.kernel.org
Cc: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Shuah Khan <shuah@kernel.org>, 
 Hannes Frederic Sowa <hannes@stressinduktion.org>, 
 linux-kselftest@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Haseeb Malik <haseebulhaq55@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790887217; l=6483;
 i=haseebulhaq55@gmail.com; s=default; h=from:subject:message-id;
 bh=nYPANP9B1BqxqdorLNrgdc2Ap2uzdmIKhfaFC2ZuQIg=;
 b=IjTxLgQADBOZwXSGnsFvnt/hWKeJZXq9xylveS10WiPanUKi9rG0v4amlpZ1koovS4lfCTXED
 cRpNdLZSGXyClXzTZ93FEGwirI+4GpCe2bqTtcNhireV2TKolQ8gdBb
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

Resolve an undefined SCI in macsec_newlink() before initializing the
SecY, so initialization and duplicate detection use the same value.
Preserve the all-ones fallback when the resulting SCI is available.

Add regression tests for duplicate rejection using default, explicit and
all-ones SCI requests, and for valid fallback and reuse after deletion.
Skip these local tests when iproute2 lacks MACsec support.

Fixes: c09440f7dcb3 ("macsec: introduce IEEE 802.1AE driver")
Link: https://lists.openwall.net/netdev/2026/09/16/11
Assisted-by: LLM
Signed-off-by: Haseeb Malik <haseebulhaq55@gmail.com>
---
Changes in v2:
- Resolve undefined SCI in macsec_newlink(), as suggested by Sabrina.
- Check local iproute2 MACsec support in the new tests, as Sashiko noted.

Link to v1: https://lore.kernel.org/netdev/20260927-fix-macsec-duplicate-sci-v1-1-085bd742c8e9@gmail.com/

Tested on arm64/virtme with KASAN and lockdep: the new regression
tests go from 5 pass/2 fail to 7 pass/0 fail. The full MACsec selftest
passes all 15 cases without skips.
---
 drivers/net/macsec.c                          |  8 ++--
 tools/testing/selftests/drivers/net/macsec.py | 57 +++++++++++++++++++++++++--
 2 files changed, 57 insertions(+), 8 deletions(-)

diff --git a/drivers/net/macsec.c b/drivers/net/macsec.c
index 78a19b134632..69686f22eda8 100644
--- a/drivers/net/macsec.c
+++ b/drivers/net/macsec.c
@@ -4143,9 +4143,6 @@ static void macsec_init_secy(struct net_device *dev, sci_t sci, u8 icv_len)
 	struct macsec_dev *macsec = macsec_priv(dev);
 	struct macsec_secy *secy = &macsec->secy;
 
-	if (sci == MACSEC_UNDEF_SCI)
-		sci = dev_to_sci(dev, MACSEC_PORT_ES);
-
 	secy->netdev = dev;
 	secy->operational = true;
 	secy->key_len = DEFAULT_SAK_LEN;
@@ -4178,7 +4175,7 @@ static int macsec_newlink(struct net_device *dev,
 	u8 icv_len = MACSEC_DEFAULT_ICV_LEN;
 	struct net_device *real_dev;
 	int err, mtu;
-	sci_t sci;
+	sci_t sci = MACSEC_UNDEF_SCI;
 
 	if (!tb[IFLA_LINK])
 		return -EINVAL;
@@ -4231,7 +4228,8 @@ static int macsec_newlink(struct net_device *dev,
 		sci = nla_get_sci(data[IFLA_MACSEC_SCI]);
 	else if (data && data[IFLA_MACSEC_PORT])
 		sci = dev_to_sci(dev, nla_get_be16(data[IFLA_MACSEC_PORT]));
-	else
+
+	if (sci == MACSEC_UNDEF_SCI)
 		sci = dev_to_sci(dev, MACSEC_PORT_ES);
 
 	/* Registration can notify listeners before returning. */
diff --git a/tools/testing/selftests/drivers/net/macsec.py b/tools/testing/selftests/drivers/net/macsec.py
index 9a83d9542e04..81003bda9b0d 100755
--- a/tools/testing/selftests/drivers/net/macsec.py
+++ b/tools/testing/selftests/drivers/net/macsec.py
@@ -34,9 +34,10 @@ def _get_features(dev):
     return ethtool(f"-k {dev}", json=True)[0]
 
 
-def _require_ip_macsec(cfg):
-    """SKIP if iproute2 on local or remote lacks 'ip macsec' support."""
-    for host in [None, cfg.remote]:
+def _require_ip_macsec(cfg=None):
+    """SKIP if iproute2 lacks MACsec locally or on cfg.remote, when given."""
+    hosts = [None, cfg.remote] if cfg is not None else [None]
+    for host in hosts:
         out = cmd("ip macsec help", fail=False, host=host)
         if "Usage" not in out.stdout + out.stderr:
             where = "remote" if host else "local"
@@ -263,6 +264,54 @@ def test_offload_state(cfg) -> None:
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
+    _require_ip_macsec()
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
+    _require_ip_macsec()
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
 
@@ -333,6 +382,8 @@ def main() -> None:
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

