From: Paul Louvel <paul.louvel@bootlin.com>
Date: Fri, 13 Mar 2026 23:00:58 +0100
Subject: [PATCH] crypto: replace broken libkcapi link in Crypto API
 documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260313-crypto-api-libkcapi-broken-link-v1-1-a218033d7f05@bootlin.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3NQQqEMAyF4atI1hOoypTqVWQWWqOGSltSEUW8u
 3V279u8/4JEwpSgLS4Q2jlx8BnlpwC79H4m5DEbKlVpVZc1WjnjFrCPjCsPzr5jkODIZ3uH+qt
 0Q8aSNgbySxSa+PgXut99P3SKL6FxAAAA
X-Change-ID: 20260313-crypto-api-libkcapi-broken-link-65069e8ce688
To: Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-crypto@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Paul Louvel <paul.louvel@bootlin.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773439265; l=1586;
 i=paul.louvel@bootlin.com; s=20260313; h=from:subject:message-id;
 bh=zS0LL2f4m8BpZe7orBEj/v0/x6tFu/8SdGToDAw0bi0=;
 b=NIAz75h6nVAXaHqDss1V8y1Brf27u6DV/G7fj85LfthqkQA8XSJmHWntcSAnqc97VUo0tAVOr
 Fs1/dKE1UTXD/oKNhHfVL2aQ1JYdDSF7+cUQl8PE7ppCNDfM79YIXyp
X-Developer-Key: i=paul.louvel@bootlin.com; a=ed25519;
 pk=eLW50NT18UAvUT5cAcYf88zNbBCZDLFXuptpyLVhVIU=
X-Endpoint-Received: by B4 Relay for paul.louvel@bootlin.com/20260313 with auth_id=681
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The "User Space Interface" section of the Crypto API documentation
contains a link to the libkcapi project that no longer works.

Update the link to point to the correct upstream location so that
users can access the library documentation.

Signed-off-by: Paul Louvel <paul.louvel@bootlin.com>
---
The "User Space Interface" of the Crypto API documentation has a broken
link to libkcapi. Replacing it with a working one.
---
 Documentation/crypto/userspace-if.rst | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/Documentation/crypto/userspace-if.rst b/Documentation/crypto/userspace-if.rst
index 021759198fe7..79e41845f611 100644
--- a/Documentation/crypto/userspace-if.rst
+++ b/Documentation/crypto/userspace-if.rst
@@ -23,7 +23,7 @@ user space, however. This includes the difference between synchronous
 and asynchronous invocations. The user space API call is fully
 synchronous.
 
-[1] https://www.chronox.de/libkcapi/index.html
+[1] https://www.chronox.de/libkcapi/
 
 User Space API General Remarks
 ------------------------------
@@ -406,4 +406,4 @@ Please see [1] for libkcapi which provides an easy-to-use wrapper around
 the aforementioned Netlink kernel interface. [1] also contains a test
 application that invokes all libkcapi API calls.
 
-[1] https://www.chronox.de/libkcapi/index.html
+[1] https://www.chronox.de/libkcapi/

---
base-commit: b84a0ebe421ca56995ff78b66307667b62b3a900
change-id: 20260313-crypto-api-libkcapi-broken-link-65069e8ce688

Best regards,
-- 
Paul Louvel <paul.louvel@bootlin.com>

