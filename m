From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 13:51:56 +0000
Subject: [PATCH BlueZ 02/10] build: tweak PKG_CHECK_MODULES calls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-autofoo-v1-2-626f6b54bd06@gmail.com>
References: <20240116-autofoo-v1-0-626f6b54bd06@gmail.com>
In-Reply-To: <20240116-autofoo-v1-0-626f6b54bd06@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413116; l=5425;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=RW5Zf7nNK2DwOoLbGkq4IW19GMpKuijCPPAeggcVrpw=;
 b=6wlQkFWxx6x6fIC4BHAroYhs7X82ZDxKVtEQYfLhjJF4Xy7jGyQ5ePM0KokZRpKVe4qel/JaF
 7Jl3fRtRceMBA+VVtSh43Tm2AgADmjxn92+BxS/9Yah0u0mgbVAfDQk
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

There's no need to call AC_SUBST after a PKG_CHECK_MODULES call, since
the variables are always set. As an example: the produced Makefile.in
and Makefile are identical before/after this change.

Similarly, we don't need the "dummy=yes" and manual AC_MSG_ERROR() call
- pkg-config (or pkgconf) will produce the same and in some cases better
  error messages.
---
 configure.ac | 59 ++++++++++++-----------------------------------------------
 1 file changed, 12 insertions(+), 47 deletions(-)

diff --git a/configure.ac b/configure.ac
index 307a2f30c..7cbfa8846 100644
--- a/configure.ac
+++ b/configure.ac
@@ -72,23 +72,16 @@ AC_CHECK_LIB(dl, dlopen, dummy=yes,
 
 AC_CHECK_HEADERS(linux/types.h linux/if_alg.h linux/uinput.h linux/uhid.h sys/random.h)
 
-PKG_CHECK_MODULES(GLIB, glib-2.0 >= 2.28, dummy=yes,
-				AC_MSG_ERROR(GLib >= 2.28 is required))
-AC_SUBST(GLIB_CFLAGS)
-AC_SUBST(GLIB_LIBS)
+PKG_CHECK_MODULES(GLIB, glib-2.0 >= 2.28)
 
 if (test "${enable_threads}" = "yes"); then
 	AC_DEFINE(NEED_THREADS, 1, [Define if threading support is required])
-	PKG_CHECK_MODULES(GTHREAD, gthread-2.0 >= 2.16, dummy=yes,
-				AC_MSG_ERROR(GThread >= 2.16 is required))
+	PKG_CHECK_MODULES(GTHREAD, gthread-2.0 >= 2.16)
 	GLIB_CFLAGS="$GLIB_CFLAGS $GTHREAD_CFLAGS"
 	GLIB_LIBS="$GLIB_LIBS $GTHREAD_LIBS"
 fi
 
-PKG_CHECK_MODULES(DBUS, dbus-1 >= 1.10, dummy=yes,
-				AC_MSG_ERROR(D-Bus >= 1.10 is required))
-AC_SUBST(DBUS_CFLAGS)
-AC_SUBST(DBUS_LIBS)
+PKG_CHECK_MODULES(DBUS, dbus-1 >= 1.10)
 
 AC_ARG_WITH([dbusconfdir], AS_HELP_STRING([--with-dbusconfdir=DIR],
 				[path to D-Bus configuration directory]),
@@ -230,10 +223,7 @@ AM_CONDITIONAL(MONITOR, test "${enable_monitor}" != "no")
 AC_ARG_ENABLE(udev, AS_HELP_STRING([--disable-udev],
 		[disable udev device support]), [enable_udev=${enableval}])
 if (test "${enable_tools}" != "no" && test "${enable_udev}" != "no"); then
-	PKG_CHECK_MODULES(UDEV, libudev >= 172, dummy=yes,
-				AC_MSG_ERROR(libudev >= 172 is required))
-	AC_SUBST(UDEV_CFLAGS)
-	AC_SUBST(UDEV_LIBS)
+	PKG_CHECK_MODULES(UDEV, libudev >= 172)
 	AC_CHECK_LIB(udev, udev_hwdb_new,
 		AC_DEFINE(HAVE_UDEV_HWDB_NEW, 1,
 			[Define to 1 if you have the udev_hwdb_new() function.]))
@@ -260,10 +250,7 @@ AC_ARG_ENABLE(mesh, AS_HELP_STRING([--enable-mesh],
 AM_CONDITIONAL(MESH, test "${enable_mesh}" = "yes")
 
 if (test "${enable_mesh}" = "yes"); then
-	PKG_CHECK_MODULES(JSONC, json-c >= 0.13, dummy=yes,
-				AC_MSG_ERROR(json-c >= 0.13 is required))
-	AC_SUBST(JSON_CFLAGS)
-	AC_SUBST(JSON_LIBS)
+	PKG_CHECK_MODULES(JSONC, json-c >= 0.13)
 fi
 
 AC_ARG_ENABLE(midi, AS_HELP_STRING([--enable-midi],
@@ -271,19 +258,13 @@ AC_ARG_ENABLE(midi, AS_HELP_STRING([--enable-midi],
 AM_CONDITIONAL(MIDI, test "${enable_midi}" = "yes")
 
 if (test "${enable_midi}" = "yes"); then
-	PKG_CHECK_MODULES(ALSA, alsa, dummy=yes,
-			AC_MSG_ERROR(ALSA lib is required for MIDI support))
-	AC_SUBST(ALSA_CFLAGS)
-	AC_SUBST(ALSA_LIBS)
+	PKG_CHECK_MODULES(ALSA, alsa)
 fi
 
 AC_ARG_ENABLE(obex, AS_HELP_STRING([--disable-obex],
 		[disable OBEX profile support]), [enable_obex=${enableval}])
 if (test "${enable_obex}" != "no"); then
-	PKG_CHECK_MODULES(ICAL, libical, dummy=yes,
-					AC_MSG_ERROR(libical is required))
-	AC_SUBST(ICAL_CFLAGS)
-	AC_SUBST(ICAL_LIBS)
+	PKG_CHECK_MODULES(ICAL, libical)
 fi
 AM_CONDITIONAL(OBEX, test "${enable_obex}" != "no")
 
@@ -295,10 +276,7 @@ AC_ARG_ENABLE([external_ell], AS_HELP_STRING([--enable-external-ell],
 				[enable external Embedded Linux library]),
 					[enable_external_ell=${enableval}])
 if (test "${enable_external_ell}" = "yes"); then
-	PKG_CHECK_MODULES(ELL, ell >= 0.39, dummy=yes,
-		AC_MSG_ERROR(Embedded Linux library >= 0.39 is required))
-	AC_SUBST(ELL_CFLAGS)
-	AC_SUBST(ELL_LIBS)
+	PKG_CHECK_MODULES(ELL, ell >= 0.39)
 fi
 if (test "${enable_external_ell}" != "yes" &&
 		(test "${enable_btpclient}" = "yes" || test "${enable_mesh}" = "yes")); then
@@ -442,17 +420,11 @@ AC_ARG_ENABLE(android, AS_HELP_STRING([--enable-android],
 AM_CONDITIONAL(ANDROID, test "${enable_android}" = "yes")
 
 if (test "${enable_android}" = "yes"); then
-	PKG_CHECK_MODULES(SBC, sbc >= 1.2, dummy=yes,
-			AC_MSG_ERROR(SBC library >= 1.2 is required))
-	AC_SUBST(SBC_CFLAGS)
-	AC_SUBST(SBC_LIBS)
+	PKG_CHECK_MODULES(SBC, sbc >= 1.2)
 fi
 
 if (test "${enable_android}" = "yes"); then
-	PKG_CHECK_MODULES(SPEEXDSP, speexdsp >= 1.2, dummy=yes,
-			AC_MSG_ERROR(SPEEXDSP library >= 1.2 is required))
-	AC_SUBST(SPEEXDSP_CFLAGS)
-	AC_SUBST(SPEEXDSP_LIBS)
+	PKG_CHECK_MODULES(SPEEXDSP, speexdsp >= 1.2)
 fi
 
 AC_DEFINE_UNQUOTED(ANDROID_STORAGEDIR, "${storagedir}/android",
@@ -466,15 +438,8 @@ if (test -z "${plugin_phonebook}"); then
 fi
 
 if (test "${plugin_phonebook}" = "ebook"); then
-	PKG_CHECK_MODULES(LIBEBOOK, [libebook-1.2 >= 3.3], dummy=yes,
-			AC_MSG_ERROR(libebook >= 3.3 is required))
-	AC_SUBST(LIBEBOOK_CFLAGS)
-	AC_SUBST(LIBEBOOK_LIBS)
-	PKG_CHECK_MODULES(LIBEDATESERVER, [libedataserver-1.2 >= 3.3],
-			dummy=yes,
-			AC_MSG_ERROR(libedataserver >= 3.3 is required))
-	AC_SUBST(LIBEDATESERVER_CFLAGS)
-	AC_SUBST(LIBEDATESERVER_LIBS)
+	PKG_CHECK_MODULES(LIBEBOOK, libebook-1.2 >= 3.3)
+	PKG_CHECK_MODULES(LIBEDATESERVER, libedataserver-1.2 >= 3.3)
 fi
 AC_SUBST(PLUGIN_PHONEBOOK, [${plugin_phonebook}])
 

-- 
2.43.0

