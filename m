From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 01 Jul 2025 10:56:44 +0200
Subject: [PATCH 3/6] docs: Add awk section for ucount sysctl entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250701-jag-sysctldoc-v1-3-936912553f58@kernel.org>
References: <20250701-jag-sysctldoc-v1-0-936912553f58@kernel.org>
In-Reply-To: <20250701-jag-sysctldoc-v1-0-936912553f58@kernel.org>
To: Kees Cook <kees@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-riscv@lists.infradead.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1085;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=dEWKHLfVWADiu1QnYIwVkFpHz0JRRQExXjCQUaLKIu4=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGhjoup1BoiQAVRdV9XfCUFoG/uF/frNFIkXC
 i+CR4U02T0/dYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoY6LqAAoJELqXzVK3
 lkFPVIAL/0vcTuIFspDtPyHHqoflZX6qS//pVY7/KpYONXZz54qbFsOYcvHsalOcGGRbEyeFThS
 KJkmT1iH2UU8KpuV8wdyHxS7BuJkSGBSCI06dqU1E7NuggI1xdSqJzpj3aj65vbrlVSF/Fw4ysg
 m+ooQgPBmxB2EjAFIL5ymNSvmEeLOtXCj8tpZf992bh3HlVjEWT0I76FstxyqDEDuKAZoeB32vC
 sre7GB8OXb8ePKNLeiICC7ntminZexu5r6dm1FWu2RRfiwx172eK9+/mKSKGfIqXJDe96/zEgC/
 Ml3+i5C5zmoqqfjW8lgE/2Ey7ipB0efkUsUJvJNg40jcITxfeIhDSs8Tj3fzqPpCSdttwqc9DPk
 E8ScOJWN71+ny43P1VI7brgjJbjWztK8I/IPYJfuqATg7tOoDH6lEP5wH/V2xM3pNIRWQMMb3NY
 Hqs/UfkRALjcAXdH/gnssypUCpgQYVLzUM89LnLP3wx67tTwqi2o1ENGRLrQaVG7hk5Cjg37hS6
 Yc=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adjust the sysctl table detection to include the macro pattern used for
the ucount ctl_tables. This prevents falsly assigning them as
non-documented ctl_tables

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 scripts/check-sysctl-docs | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/scripts/check-sysctl-docs b/scripts/check-sysctl-docs
index 568197cb1c0a84147785f05aabbbc6ab9dd896bc..3166012b9c6ea4435dc77afaadcff3a4944b1ca8 100755
--- a/scripts/check-sysctl-docs
+++ b/scripts/check-sysctl-docs
@@ -130,6 +130,14 @@ curtable && /\.procname[\t ]*=[\t ]*".+"/ {
     file[curentry] = FILENAME
 }
 
+curtable && /UCOUNT_ENTRY.*/ {
+    match($0, /UCOUNT_ENTRY\("([^"]+)"\)/, names)
+    curentry = names[1]
+    if (debug) print "Adding entry " curentry " to table " curtable
+    entries[curtable][curentry]++
+    file[curentry] = FILENAME
+}
+
 /register_sysctl.*/ {
     match($0, /register_sysctl(|_init|_sz)\("([^"]+)" *, *([^,)]+)/, tables)
     if (debug) print "Registering table " tables[3] " at " tables[2]

-- 
2.47.2

