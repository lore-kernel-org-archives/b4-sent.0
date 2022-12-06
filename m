From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Tue, 06 Dec 2022 16:37:26 -0500
Subject: [PATCH RFC v5 2/2] Rename linux into pengux
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20221205-bupkes-bogus-v5-2-4f0062764fb3@linuxfoundation.org>
References: <20221205-bupkes-bogus-v5-0-4f0062764fb3@linuxfoundation.org>
In-Reply-To: <20221205-bupkes-bogus-v5-0-4f0062764fb3@linuxfoundation.org>
To: Linux Devver <konstantin.ryabitsev@linux.dev>, Coach K <coachk@hey.com>
Cc: Le Castor Anxieux <k@castoranxieux.ca>, Dev Nuller <devnull@kernel.org>, Konstantin Ryabitsev <konstantin@linuxfoundation.org>, Googler Goog <mricon@gmail.com>
X-Mailer: b4 0.11.0-dev-403b7
X-Developer-Signature: v=1; a=openpgp-sha256; l=551;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=S6XGzjv5YZA8TZwLloqVXtlsJDoi3yXibWtGw7KGo78=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJL7t0npPF54aCq76dQMq0OaPD/nmUZYd3iWbZ8RcvNrIkez
 0O9XHaUsDGJcDLJiiixl+2I3BRU+9JBL7zGFmcPKBDKEgYtTACZivIjhf+iO0Nt8UyIOx/2Y0fsm77
 DpNMsADtm/NXm/e0Rj591UOsXw398yuEDp1RqtqNyYYrtT1984f23bP8HqWVOyu3HA7H+KDAA=
X-Developer-Key: i=konstantin@linuxfoundation.org; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for konstantin@linuxfoundation.org/default with auth_id=3
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

I want to make commits.

Cc: Googler Goog <mricon@gmail.com>
Signed-off-by: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
---
 README | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/README b/README
index 669ac7c32292..fccb839e9a40 100644
--- a/README
+++ b/README
@@ -1,5 +1,5 @@
-Linux kernel
-============
+Pengux kernel
+=============
 
 There are several guides for kernel developers and users. These guides can
 be rendered in a number of formats, like HTML and PDF. Please read

-- 
2.38.1
