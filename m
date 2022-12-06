From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Tue, 06 Dec 2022 15:09:52 -0500
Subject: [PATCH RFC v4 2/2] Rename linux into pengux
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20221205-bupkes-bogus-v4-2-cb5f1e01c591@linuxfoundation.org>
References: <20221205-bupkes-bogus-v4-0-cb5f1e01c591@linuxfoundation.org>
In-Reply-To: <20221205-bupkes-bogus-v4-0-cb5f1e01c591@linuxfoundation.org>
To: Linux Devver <konstantin.ryabitsev@linux.dev>, Coach K <coachk@hey.com>
Cc: Le Castor Anxieux <k@castoranxieux.ca>, Dev Nuller <devnull@kernel.org>, Konstantin Ryabitsev <konstantin@linuxfoundation.org>, Googler Goog <mricon@gmail.com>
X-Mailer: b4 0.11.0-dev-acc53
X-Developer-Signature: v=1; a=openpgp-sha256; l=551;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=S6XGzjv5YZA8TZwLloqVXtlsJDoi3yXibWtGw7KGo78=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJL7F07u4bVddCzy2aNJrvzp7Ey7by4vTbvHdN2mUvqSufni
 m61HO0pZGMS4GGTFFFnK9sVuCip86CGX3mMKM4eVCWQIAxenAEwkmoGR4cuWGaU8R4tzZz0qCck9I8
 x17ZILS3nd1uvLeOZHZ1f+dWP4K5qrJnF0dZ3F2rztK04zbTMXU/XNnbWoOU96xvIr5dfmswMA
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
