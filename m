From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Fri, 26 Jan 2024 14:43:51 +0000
Subject: [PATCH 2/2] make: install/uninstall tools symlinks to kmod
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240126-master-v1-2-6257d039a30a@gmail.com>
References: <20240126-master-v1-0-6257d039a30a@gmail.com>
In-Reply-To: <20240126-master-v1-0-6257d039a30a@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706280230; l=1402;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=N6QdxuIRatl9gn+qNQ/NgGZ033RgojWqbfTqQeySBZI=;
 b=9YYI/y3zGT94hO2jfDdxyFiWlQf//iiBC1y14zCRLRWd7eog/qpW5Y17kwKa1E9AHWtMUKkuE
 cCHRtFNsLCHCu2nmC0o96Dms78VVujln/I5K8fjnUxfIhd5oDcd7Wr/
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

Currently we create symlinks like modprobe (pointing to kmod), during
the normal `make` build. Although those were never installed.

Add a few lines in the install-exec-hook, to ensure they're present at
`make install` time. Thus one can actually use those without additional
changes. As an added bonus, distributions can drop the similar hunk from
their packaging.

Signed-off-by: Emil Velikov <emil.velikov@collabora.com>
---
Out of curiosity: are there any plans about releasing v32? I'm
interested in the recent /usr/lib/modules (module_directory) patches.

Thanks o/
---
 Makefile.am | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/Makefile.am b/Makefile.am
index 4062d81..a22d1b1 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -111,9 +111,19 @@ install-exec-hook:
 		ln -sf $$so_img_rel_target_prefix$(rootlibdir)/$$so_img_name $(DESTDIR)$(libdir)/libkmod.so && \
 		mv $(DESTDIR)$(libdir)/libkmod.so.* $(DESTDIR)$(rootlibdir); \
 	fi
+if BUILD_TOOLS
+	for tool in insmod lsmod rmmod depmod modprobe modinfo; do \
+		$(LN_S) $(bindir)/kmod $(DESTDIR)$(bindir)/$$tool; \
+	done
+endif
 
 uninstall-hook:
 	rm -f $(DESTDIR)$(rootlibdir)/libkmod.so*
+if BUILD_TOOLS
+	for tool in insmod lsmod rmmod depmod modprobe modinfo; do \
+		rm -f $(DESTDIR)$(bindir)/$$tool; \
+	done
+endif
 
 if BUILD_TOOLS
 bin_PROGRAMS = tools/kmod

-- 
2.43.0

