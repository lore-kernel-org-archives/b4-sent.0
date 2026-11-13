From: =?utf-8?q?St=C3=A9phane_COLIN?= <bigbob.fun@gmail.com>
Subject: [PATCH 0/7] openconnect: Fix GlobalProtect authentication,
 reconnect and split routes
Date: Fri, 13 Nov 2026 16:34:50 +0100
Message-Id: <20261113-openconnect-gp-fixes-v1-0-1f7f6922d88f@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIABou92oC/x3LQQqAIBBA0avErBvIQoWuEi1immw2o2hEEN49a
 fn4/BcKZ+ECc/dC5luKRG0wfQd0bhoYZW+GcRidMWbCmFgpqjJdGBIe8nBBbydLnqw7dgdtTZn
 /0M5lrfUDK3AYmmYAAAA=
To: connman@lists.linux.dev
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794584090; l=2284;
 i=bigbob.fun@gmail.com; s=20261113; h=from:subject:message-id;
 bh=EFshlAO7+Q6jxcB9wR4fbD3C3/tlBTEQaI4mKje+WMw=;
 b=SdVZd3+7ZlUU4lH5iCbIgmO2SD6E/Lq3ZRYnrb81TxSKZZb/pyUJ7/eK9nOEVAwfrzOuSmLLW
 1xaLTMWn3fEB+FJI0HRnrqXh2OeUNG7RXY/Iu/OV1zrpBEMABE5QrDU
X-Developer-Key: i=bigbob.fun@gmail.com; a=ed25519;
 pk=MoY1DAn0hlhveZhsN9JyLnuWS/CGqJHTad4MaTL8HgY=
X-Endpoint-Received: by B4 Relay for bigbob.fun@gmail.com/20261113 with auth_id=1512
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes the OpenConnect plugin with a Palo Alto GlobalProtect
gateway (AuthType userpass, built-in authentication of connman-vpnd), the
handling of openconnect's own reconnection after a suspend, and split
routes pushed by the gateway.

1. The protocol was only given to the openconnect process started after
   authentication: the built-in authentication always used AnyConnect,
   POSTed to /gateway and got 404 from a GlobalProtect gateway.
2. "attempt-reconnect" and "reconnect" from the vpnc-script were handled
   as a disconnect: the provider was torn down while openconnect was
   still running, leaving an orphaned process.
3. GlobalProtect names its password field "passwd": an empty password
   was sent...
4. ...and the rejected credentials were resubmitted in a tight loop
   (~50 times), which can lock an account.
5. Split routes without a gateway (CISCO_SPLIT_INC_*) were never
   signalled to connmand.
6. _MASKLEN was matched as _MASK, so IPv4 netmasks became "16", "32"...
7. The username was never offered again in the credentials request.

Tested on a phone running a ConnMan 1.40 based build (Sailfish OS) against
a GlobalProtect gateway with MFA: login from the native UI, several
reconnections after suspend, 25 split routes installed with the right
netmasks. This series is the same change ported to current master; it
builds without warnings here but was not run on master itself.

---
Stéphane COLIN (7):
      openconnect: Set protocol before obtaining the cookie
      openconnect: Do not treat reconnect reasons as disconnect
      openconnect: Fill the GlobalProtect "passwd" form field
      openconnect: Limit repeated credential forms
      vpn-provider: Signal routes without gateway
      openconnect: Do not take _MASKLEN for _MASK in split routes
      openconnect: Offer the username again on the next login

 vpn/plugins/openconnect.c | 53 ++++++++++++++++++++++++++++++++++++++++-------
 vpn/vpn-agent.c           |  3 ++-
 vpn/vpn-provider.c        |  7 ++++++-
 3 files changed, 53 insertions(+), 10 deletions(-)
---
base-commit: 9e46e4a021cd8566b942d1a72b41b14a0a58f506
change-id: 20261113-openconnect-gp-fixes-7535c7c56fd6

Best regards,
-- 
Stéphane COLIN <bigbob.fun@gmail.com>

