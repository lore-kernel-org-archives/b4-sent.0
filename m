From: Nikita Ofitserov <himikof@gmail.com>
Date: Thu, 28 Aug 2025 17:16:12 +0300
Subject: [PATCH v2 10/15] bcachefs: Fix outdated documentation comment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250828-better-progress-v2-10-c088a2003940@gmail.com>
References: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
In-Reply-To: <20250828-better-progress-v2-0-c088a2003940@gmail.com>
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, Nikita Ofitserov <himikof@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=656; i=himikof@gmail.com;
 h=from:subject:message-id; bh=Ja5AdRlLz1IgrvsbQ5f5meoJxfm3EYsfj2T8f5z89XA=;
 b=owGbwMvMwCW2edHtzWZP9DIYT6slMWRsSDnUuL0//6P4iSLWi/VPLX7q2V9mXB0k37icf3Lnj
 6mPwp6kdpSyMIhxMciKKbJ8WPL1z5pM6z+WQnsNYeawMoEMYeDiFICJ6MQzMmy5LXNp5f2I68Za
 IheKlpdvTl+zLljfpvPrvtRjW1T9WMUY/imxhfQEfVWdFfZ11735Hh829s/a7uYrsuRB33wxC7e
 wm5wA
X-Developer-Key: i=himikof@gmail.com; a=openpgp;
 fpr=F0A4F5FCAC693BFC3912BD31B3A2DBB336E42E68
X-Endpoint-Received: by B4 Relay for himikof@gmail.com/default with auth_id=452
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Nikita Ofitserov <himikof@gmail.com>
---
 fs/bcachefs/bcachefs_format.h | 1 -
 1 file changed, 1 deletion(-)

diff --git a/fs/bcachefs/bcachefs_format.h b/fs/bcachefs/bcachefs_format.h
index b2de993d802b128cb503740d41028e51c14110ee..0839397105a9d20bcdb99090b508dcff2e0f1886 100644
--- a/fs/bcachefs/bcachefs_format.h
+++ b/fs/bcachefs/bcachefs_format.h
@@ -654,7 +654,6 @@ struct bch_sb_field_ext {
 /*
  * field 1:		version name
  * field 2:		BCH_VERSION(major, minor)
- * field 3:		recovery passess required on upgrade
  */
 #define BCH_METADATA_VERSIONS()						\
 	x(bkey_renumber,		BCH_VERSION(0, 10))		\

-- 
2.50.1

