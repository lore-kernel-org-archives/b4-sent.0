From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 27 Jun 2025 11:27:26 +0200
Subject: [PATCH 2/5] sysctl: Removed unused variable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250627-jag-sysctl-v1-2-20dd9801420b@kernel.org>
References: <20250627-jag-sysctl-v1-0-20dd9801420b@kernel.org>
In-Reply-To: <20250627-jag-sysctl-v1-0-20dd9801420b@kernel.org>
To: Kees Cook <kees@kernel.org>, Shuah Khan <shuah@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=685;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=O0ypzQeGPRlM3z8kh5kwMJv1JvpRZXn0U0UtN6aCpRM=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGheZIl5s5St2dBl54Hk4RjroiWdqlkUFAugj
 +e0QJdUODMiRYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoXmSJAAoJELqXzVK3
 lkFPcmoL/i14QMIIr0HafzdK8WfZqc/c0dndrNGEcIjJiCNDSitIjcCIRGLqDi93jAbZnRBeXRS
 NbQdw2USHPBqU28c8caCMCSxaXKiWUsUGa8z4HUMY+44793BI8nBTx3yWzpXSBzQyRHcon/7Ceh
 lWeOqlfCLvO7+ql/DyXh2pxiNCEyNFlk98qV5cQl/+toB0vy9m/6m6mrXUjrtePJoQDqAE7bYlU
 35aqjc/a42HM+34l/2UsBYwk9RKhFu15qXBzp0mrUZjNxkcmlRrVea5URZFjcRgoZgFhskKhnxa
 nVhzi34+I+w1+qUXA5icwltS1p8/BlzPkO3tug4t/fLjyJOSsnVnxB+mGzk7VAUmpx/BY4+fJBk
 jwSx9qLcDgS32jj5YhQdGUEF57Iz3KVBIVyEQrT2cHPRekttG0PMx/G4rFG+/MwLEe+QbY6GdiE
 VGwVqaEZPP+AblDsB9O2DnMgZmh3DJb2azCIqpmbX5Hjfj1ylOa8xrH63KiqeoPfVq6is+19pu5
 G8=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove unaligned_dump_stack from sysctl.h; it is no longer used or
defined.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 include/linux/sysctl.h | 1 -
 1 file changed, 1 deletion(-)

diff --git a/include/linux/sysctl.h b/include/linux/sysctl.h
index 30bcbc59d12d2f4cec7545e7ee3f5ea5f0eefbd7..92e9146b1104123d3dc0ff004bd681861e297581 100644
--- a/include/linux/sysctl.h
+++ b/include/linux/sysctl.h
@@ -243,7 +243,6 @@ int do_proc_douintvec(const struct ctl_table *table, int write,
 		      void *data);
 
 extern int unaligned_enabled;
-extern int unaligned_dump_stack;
 extern int no_unaligned_warning;
 
 #else /* CONFIG_SYSCTL */

-- 
2.47.2

