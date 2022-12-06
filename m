From: Konstantin Ryabitsev <konstantin@linuxfoundation.org>
Date: Tue, 06 Dec 2022 14:25:52 -0500
Subject: [PATCH RFC v4 2/2] Rename linux into pengux
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20221205-bupkes-bogus-v4-2-420cc99d3170@linuxfoundation.org>
References: <20221205-bupkes-bogus-v4-0-420cc99d3170@linuxfoundation.org>
In-Reply-To: <20221205-bupkes-bogus-v4-0-420cc99d3170@linuxfoundation.org>
To: Linux Devver <konstantin.ryabitsev@linux.dev>, Coach K <coachk@hey.com>
Cc: Le Castor Anxieux <k@castoranxieux.ca>, Dev Nuller <devnull@kernel.org>, Konstantin Ryabitsev <konstantin@linuxfoundation.org>
X-Mailer: b4 0.11.0-dev-acc53
X-Developer-Signature: v=1; a=openpgp-sha256; l=514;
 i=konstantin@linuxfoundation.org; h=from:subject:message-id;
 bh=If5v8auDXbISwM6OtXPoY9da8b+ctuLeXlVik/2iu0Q=;
 b=owGbwMvMwCW27YjM47CUmTmMp9WSGJL7p3tq+e4+Zdn7d36WR6KBV7d8r1T4IkXuxws9PH7sjj8c
 6azaUcrCIMbFICumyFK2L3ZTUOFDD7n0HlOYOaxMIEMYuDgFYCLvDzP8z+b3enJMLyx/6aHn66qaWl
 8Lrt9REtf6ROjpyRv8XNwLGBgZHjc+vbw+9Y/PBZ58Nsaj831mX9CdNll5TuRkxa5o4Uc3+QA=
X-Developer-Key: i=konstantin@linuxfoundation.org; a=openpgp;
 fpr=DE0E66E32F1FDD0902666B96E63EDCA9329DD07E
X-Endpoint-Received: by B4 Submission Endpoint for konstantin@linuxfoundation.org/default with auth_id=3
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

I want to make commits.

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
