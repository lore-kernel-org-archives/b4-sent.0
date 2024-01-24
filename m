From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 24 Jan 2024 23:44:03 +0000
Subject: [PATCH BlueZ 9/9] build: ship all config files with
 --enable-datafiles
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240124-disto-patches-v1-9-97e0eb5625a3@gmail.com>
References: <20240124-disto-patches-v1-0-97e0eb5625a3@gmail.com>
In-Reply-To: <20240124-disto-patches-v1-0-97e0eb5625a3@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706139864; l=1705;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=WcwicGjaSO+V6cupapMGhMCvR7ck7Ya4gUcQRwXNGwI=;
 b=a7Fl0HIZ57bBn2edsjUAYUYgph+/lnsbJ6+I/euXHaxIcekgg5QE6CMNN+qUfThTkJhT5VgN0
 oydUmZUnW/3CFlW8h6AuNWgal8HQus2gHr/AhWI9P7o/5FyWVR8vCeH
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

Currently we ship only the dbus/systemd policy files and omit the other
four - /etc/bluetooth/{main,mesh-main,input,network}.conf.

Outside of those files, there is no documentation what the defaults are
and the other possible options. A number of distributions (Arch, Gentoo,
Fedora) have opted to manually copy those into the package. Alas this
does not scale and leaves other distros at disadvantage, in a sense.

Note: we need a custom install target to ensure confdir and statedir
have the correct permissions.
---
Some distributions do toggle some of the default values, by patching the
source tree. Future patches will add support for more maintainable
configuration handling akin to `man sysctl.d`.
---
 Makefile.am   | 8 +++++++-
 Makefile.mesh | 1 +
 2 files changed, 8 insertions(+), 1 deletion(-)

diff --git a/Makefile.am b/Makefile.am
index e738eb3a5..9c19cec49 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -31,11 +31,17 @@ AM_LDFLAGS = $(MISC_LDFLAGS)
 confdir = $(sysconfdir)/bluetooth
 statedir = $(localstatedir)/lib/bluetooth
 
+install-data-hook:
+	install -dm555 $(DESTDIR)$(confdir)
+	install -dm700 $(DESTDIR)$(statedir)
+
 if DATAFILES
 dbusdir = $(DBUS_CONFDIR)/dbus-1/system.d
 dbus_DATA = src/bluetooth.conf
 
-conf_DATA =
+conf_DATA = src/main.conf
+conf_DATA += profiles/input/input.conf
+conf_DATA += profiles/network/network.conf
 state_DATA =
 endif
 
diff --git a/Makefile.mesh b/Makefile.mesh
index 63f085de1..930262d53 100644
--- a/Makefile.mesh
+++ b/Makefile.mesh
@@ -3,6 +3,7 @@ if MESH
 
 if DATAFILES
 dbus_DATA += mesh/bluetooth-mesh.conf
+conf_DATA += mesh/mesh-main.conf
 endif
 
 if SYSTEMD

-- 
2.43.0

