From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 13 Jan 2025 12:53:02 +0100
Subject: [PATCH RESEND 04/12] Makefile: Add virsh and libvirtd to minimum
 dependencies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250113-jag-bringup_fixes-v1-4-fb28030b1f26@kernel.org>
References: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
In-Reply-To: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, mcgrof@kernel.org, 
 da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=559;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=Kt0zBkpB+Wq/cF1K12NdeZvH0eWmgaNhm+yWtxTqcHo=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGeE/qQVaCgbzQ9ZJmQaOpa4hqjUUU4ZnZzZn
 9IaSEx+6YzNB4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnhP6kAAoJELqXzVK3
 lkFPeiEL/i+U/tdSF/p5fEuuko43+zECQyKSwGnA8IyR73DBr1lvWd5/n22Z7SGmbm1W6XrCfrl
 9HzO1m3LTD0mUSf/AmkrTZ0XLcY4tERNEj6HFFJnHgx0DGJnQTujlYUuAFwB8LdGslKH1EBTWFF
 k+/ziP5rNm+zI0//vDfFfJrATsM1zPo4ebu6KIsSjQ0HphSqSqIsydo+E5o2H4B7mFDAw+ou+Vf
 sRVDzbeJ37uwYTmAhte5gsWCIFQNoqnp6RB4Oi7EgWkVtUnwOkmSrGMZcZXOmEyrYMpf0gGLBY7
 TcRhZ6x6zNw2KfWRt4vvjwAeQv3+BhfDVD2HWyqaKXnUYLUpKN7Oq9kU3WXOd5/dXHdUq7fmEIe
 U6Rn1tt25jUoSErYvGBvUjlPqQ+eTVKKVMbFXboL18y52jvC+YQsX5kBmc93Bg9myvLe0enCWxD
 gu552smrBKnGVcGa/2vpy5RjL/ZZIRYUzyOC7+nUVH96F/7xzRl7OZVa2JQ80rc8hQw5eVxJkV7
 aU=
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

