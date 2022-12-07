From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Wed, 07 Dec 2022 15:42:53 -0500
Subject: [PATCH RFC v5 1/2] Makefile: Make it a ninja penguin
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20221205-bupkes-bogus-v5-1-9af8cfc6eb38@linuxfoundation.org>
References: <20221205-bupkes-bogus-v5-0-9af8cfc6eb38@linuxfoundation.org>
In-Reply-To: <20221205-bupkes-bogus-v5-0-9af8cfc6eb38@linuxfoundation.org>
To: Linux Devver <konstantin.ryabitsev@linux.dev>, Coach K <coachk@hey.com>
Cc: Le Castor Anxieux <k@castoranxieux.ca>, Dev Nuller <devnull@kernel.org>, Konstantin Ryabitsev <konstantin@linuxfoundation.org>
X-Mailer: b4 0.11.0-dev-93339
X-Developer-Signature: v=1; a=openpgp-sha256; l=529;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=cXynJgYkbdPp8JruftiPTSQD1ensIQWtABkMlaXST5w=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJIn/LoXubvrbWngjJuJqb9alsxL99kc/N/8u0CgpVT08tXz
 upa2dJSyMIhxMciKKbKU7YvdFFT40EMuvccUZg4rE8gQBi5OAZjIpmxGhqvPYvu9rML/HHOQPdSTd1
 OluLNN0/PGWvbVuQ6s54+VnGH4w/1XjINnlfXHyTIGNpPPvepjW7d7G0cr0+o4nyU6hZ3TeAA=
X-Developer-Key: i=konstantin@linuxfoundation.org; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for konstantin@linuxfoundation.org/default with auth_id=3
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Sloths can't be ninjas.

Signed-off-by: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
---
 Makefile | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Makefile b/Makefile
index 0992f827888d..a61621a36798 100644
--- a/Makefile
+++ b/Makefile
@@ -3,7 +3,7 @@ VERSION = 6
 PATCHLEVEL = 1
 SUBLEVEL = 0
 EXTRAVERSION = -rc8
-NAME = Hurr durr I'ma ninja sloth
+NAME = Hurr durr I'ma ninja penguin
 
 # *DOCUMENTATION*
 # To see a list of typical targets execute "make help"

-- 
2.38.1
