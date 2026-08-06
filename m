From: Christoph Paasch <cpaasch@openai.com>
Date: Thu, 06 Aug 2026 12:49:22 -0700
Subject: [PATCH net-next] mailmap: add entries for Christoph Paasch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260806-b4-mailman-v1-1-b4d7bc0ffd1c@openai.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQrCMBBEf6Xs2cUYbC3+ivSQxKldsaskUQql/
 26ix5l581ZKiIJE52aliI8keWoJh11DYXJ6A8u1ZLLGdqY3Hfsjz04es1M2FqPpEVqcWiqHV8Q
 oy092IUVmxZJp+C/p7e8Iuboq610C++g0TLUqdIX3Ra20bV9nBzDDlwAAAA==
X-Change-ID: 20260806-b4-mailman-02ef08ec5e75
To: netdev@vger.kernel.org
Cc: Matthieu Baerts <matttbe@kernel.org>, 
 Christoph Paasch <cpaasch@openai.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786045813; l=1364;
 i=cpaasch@openai.com; s=20250712; h=from:subject:message-id;
 bh=RwSB4S74uMgM7hwtS7mI8TFWqu8YItSh26B7RAY+3a0=;
 b=szBPnHJNE9QAFnLulcPxuz7mRbQwnDzI9WaiODvduPZs4PEE/+SdUpVdVBmIt8PZzLhaV2CgR
 oScyKm8VsLcB88gSNDz3dgicd//HuHZiUmFs6kaUiAf6Tu5WOnDNaz4
X-Developer-Key: i=cpaasch@openai.com; a=ed25519;
 pk=1HRHZlVUZPziMZvsAQFvP7n5+uEosTDAjXmNXykdxdg=
X-Endpoint-Received: by B4 Relay for cpaasch@openai.com/20250712 with auth_id=459
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Map the email addresses used for previous kernel contributions to the
current OpenAI address. This prevents get_maintainer.pl from listing
historical addresses as patch recipients.

Suggested-by: Matthieu Baerts <matttbe@kernel.org>
Assisted-by: Codex:gpt-5.6-sol
Signed-off-by: Christoph Paasch <cpaasch@openai.com>
---
 .mailmap | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/.mailmap b/.mailmap
index fd5e272bca9a..85e022641168 100644
--- a/.mailmap
+++ b/.mailmap
@@ -210,6 +210,10 @@ Christophe Ricard <christophe.ricard@gmail.com>
 Christopher Obbard <christopher.obbard@linaro.org> <chris.obbard@collabora.com>
 Christoph Hellwig <hch@lst.de>
 Christoph Manszewski <c.manszewski@gmail.com> <christoph.manszewski@intel.com>
+Christoph Paasch <cpaasch@openai.com> <christoph.paasch@gmail.com>
+Christoph Paasch <cpaasch@openai.com> <christoph.paasch@student.uclouvain.be>
+Christoph Paasch <cpaasch@openai.com> <christoph.paasch@uclouvain.be>
+Christoph Paasch <cpaasch@openai.com> <cpaasch@apple.com>
 Chuck Lever <cel@kernel.org> <chuck.lever@oracle.com>
 Chuck Lever <cel@kernel.org> <cel@netapp.com>
 Chuck Lever <cel@kernel.org> <cel@citi.umich.edu>

---
base-commit: c206fc0705d1050d9bce22ac4eb94bb062443cd6
change-id: 20260806-b4-mailman-02ef08ec5e75

Best regards,
--  
Christoph Paasch <cpaasch@openai.com>

