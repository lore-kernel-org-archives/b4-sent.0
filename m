From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 13 Jan 2025 12:53:10 +0100
Subject: [PATCH RESEND 12/12] ansible: Set running_user explicitly to the
 USER var of the script
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250113-jag-bringup_fixes-v1-12-fb28030b1f26@kernel.org>
References: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
In-Reply-To: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, mcgrof@kernel.org, 
 da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=643;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=jRfRt47UG+s1NGe9WMjH6iz6cKXD6GqKWu00bPFiEVg=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGeE/qnVU5Nc7jZ9JN+KPKbgPppv2umrILvZf
 lmHbnh7bRo65IkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnhP6pAAoJELqXzVK3
 lkFPsrUMAIM2AyiSK0gYw/qlHsMMqNAEEcxtDLAiWxhq+s2c0578cB6JhHFdoWbYVrCT69n7zmQ
 xZ4D6JvS203XGn1IUqH09gJylZT4W3a1N42Iiye8vprt1LTdJg/y1jdbjCiLu4dZfTOUcH7Yl0p
 l2v/JQWpFu0HFpLLpiEcBj9GL3W3cCqbUe9ZJgBaHiVBGtWudzJU9i0wfFa5c6CukB7w8zrhz2t
 /5HSKVEke9kRNd2fVGCyHtOIz7SJWKK0/fY2cFHx9AvnopBn2tTKJcfShanINMgk3Q/FUPR96+J
 tIj9xbNCQRF5WKE8lKV7WKwq7upyn7/ofqKZt/9JIWxLXGqwLwgXK8ODINpsDPtwI0rBdrVcywB
 +TAAKLBIQ6h4r2SxEXY6yvcehUCqI/RVA9PG6lA7xC5mGHhgkb3WdUSfAFNMMqG41UQUtq0UrJn
 MdrRLN1zyO2JaN/hZuZeVfVGqf6bUWhhd6XIRcL1Y+KS/4SGjqGLmfJWwa8HKqM+ZRKWcPnzfz5
 Kc=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 scripts/guestfs.Makefile | 1 +
 1 file changed, 1 insertion(+)

diff --git a/scripts/guestfs.Makefile b/scripts/guestfs.Makefile
index 480bc4f..f463ecc 100644
--- a/scripts/guestfs.Makefile
+++ b/scripts/guestfs.Makefile
@@ -77,6 +77,7 @@ bringup_guestfs: $(GUESTFS_BRINGUP_DEPS)
 		--inventory localhost, \
 		playbooks/bringup_guestfs.yml \
 		-e 'ansible_python_interpreter=/usr/bin/python3' \
+		-e 'running_user=$(USER)' \
 		--extra-vars=@./extra_vars.yaml \
 		--tags config-check,network,build-deps
 	$(Q)$(TOPDIR)/scripts/bringup_guestfs.sh

-- 
2.44.2

