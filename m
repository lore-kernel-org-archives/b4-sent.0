From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 18 Dec 2024 11:29:58 +0100
Subject: [PATCH 04/12] Makefile: Add virsh and libvirtd to minimum
 dependencies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241218-jag-bringup_fixes-v1-4-0bf2e07c640c@kernel.org>
References: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
In-Reply-To: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=559;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=Kt0zBkpB+Wq/cF1K12NdeZvH0eWmgaNhm+yWtxTqcHo=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGdipCy0uiYOlG+25TwBqI1CJcSaX+aGnTDHm
 lUzR5cOo27GaIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnYqQsAAoJELqXzVK3
 lkFPSAcL/i77XX3eLwproRtsl2ol5fTYtfBOza7ek+DuU56YhkLXQ+6oX71arZwjdZyki6PFeCJ
 FYVv58IDauE/soUHFJSIhxZlf5ZyiraUu7fjzXJp8OVH0vNKRvXKY9cN5pdRyaaBbgDMshz//SJ
 yAPuI31SHz7GFnY2X1I0myQm4QowaSOGDeCqYhxP49ztlS1QYf+ggC4JU9HiHsa6l2ZOLSbIUez
 gKc/A4PQ09B3vBaOygyXUJJlD2ztkvSNRfWZnSLMjG3u+cBDX0tK7PSwgVv4YGSqXUUVZIXTKcj
 8YKq18ds0YQ//XARV8xg8I6UBzvVxCUm/uN2g0zCROvFvnSiLkTDgZLupXBt/FOW/Zdo78CorKY
 RdDLLgkoinDy6ktndZfnto7lpaGPuC1OaI4+hL4DtZtRqLKATpUYHk+BR5KK4fZdBwhx8FHYi4f
 9fCla+AM6nI+2cmISzbKWJoTjd3Dr2WeaoQ8Hk+3Ue1AYSP/3Ez/rrM7neVNVUtCFH5t+LzoSM8
 3c=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Running scripts like bring up depend on 'virsh' being available.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 Makefile.min_deps | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Makefile.min_deps b/Makefile.min_deps
index a1cb99a..d1251b4 100644
--- a/Makefile.min_deps
+++ b/Makefile.min_deps
@@ -13,6 +13,8 @@ BINARY_DEPS += ansible-playbook
 ifneq (y,$(CONFIG_KDEVOPS_FIRST_RUN))
 ifeq (y,$(CONFIG_GUESTFS))
 BINARY_DEPS += virt-builder
+BINARY_DEPS += virsh
+BINARY_DEPS += libvirtd
 endif
 endif
 

-- 
2.44.2

