AC_DEFUN([GUILE_PKG], [
    PKG_PROG_PKG_CONFIG
    _guile_versions_to_search="m4_default([$1], [3.0 2.0 1.8])"
    if test -n "$GUILE_EFFECTIVE_VERSION"; then
        _guile_tmp=""
        for v in $_guile_versions_to_search; do
            if test "$v" = "$GUILE_EFFECTIVE_VERSION"; then
                _guile_tmp=$v
            fi
        done
        if test -z "$_guile_tmp"; then
            AC_MSG_FAILURE([searching for guile development files for versions $_guile_versions_to_search, but previously found $GUILE version $GUILE_EFFECTIVE_VERSION])
        fi
        _guile_versions_to_search=$GUILE_EFFECTIVE_VERSION
    fi
    GUILE_EFFECTIVE_VERSION=""
    _guile_errors=""
    for v in $_guile_versions_to_search; do
        if test -z "$GUILE_EFFECTIVE_VERSION"; then
            AC_MSG_NOTICE([checking for guile $v])
            PKG_CHECK_EXISTS([guile-$v], [GUILE_EFFECTIVE_VERSION=$v], [])
        fi
    done

    if test -z "$GUILE_EFFECTIVE_VERSION"; then
        AC_MSG_ERROR([
No Guile development packages were found.

Please verify that you have Guile installed.  If you installed Guile
from a binary distribution, please verify that you have also installed
the development packages.  If you installed it yourself, you might need
to adjust your PKG_CONFIG_PATH; see the pkg-config man page for more.
])
    fi
    AC_MSG_NOTICE([found guile $GUILE_EFFECTIVE_VERSION])
    AC_SUBST([GUILE_EFFECTIVE_VERSION])
])

AC_DEFUN([GUILE_FLAGS], [
    AC_REQUIRE([GUILE_PKG])
    PKG_CHECK_MODULES(GUILE, [guile-$GUILE_EFFECTIVE_VERSION])

    dnl GUILE_CFLAGS and GUILE_LIBS are already defined and AC_SUBST'd by
    dnl PKG_CHECK_MODULES.  But GUILE_LIBS to pkg-config is GUILE_LDFLAGS
    dnl to us.

    GUILE_LDFLAGS=$GUILE_LIBS

    dnl Determine the platform dependent parameters needed to use rpath.
    dnl AC_LIB_LINKFLAGS_FROM_LIBS is defined in gnulib/m4/lib-link.m4 and needs
    dnl the file gnulib/build-aux/config.rpath.
    AC_LIB_LINKFLAGS_FROM_LIBS([GUILE_LIBS], [$GUILE_LDFLAGS], [])
    GUILE_LIBS="$GUILE_LDFLAGS $GUILE_LIBS"
    AC_LIB_LINKFLAGS_FROM_LIBS([GUILE_LTLIBS], [$GUILE_LDFLAGS], [yes])
    GUILE_LTLIBS="$GUILE_LDFLAGS $GUILE_LTLIBS"

    AC_SUBST([GUILE_EFFECTIVE_VERSION])
    AC_SUBST([GUILE_CFLAGS])
    AC_SUBST([GUILE_LDFLAGS])
    AC_SUBST([GUILE_LIBS])
    AC_SUBST([GUILE_LTLIBS])
])

AC_DEFUN([GUILE_SITE_DIR], [AC_REQUIRE([GUILE_PKG])
    AC_MSG_CHECKING(for Guile site directory)
    GUILE_SITE=`$PKG_CONFIG --print-errors --variable=sitedir guile-$GUILE_EFFECTIVE_VERSION`
    AC_MSG_RESULT($GUILE_SITE)
    if test "$GUILE_SITE" = ""; then
        AC_MSG_FAILURE(sitedir not found)
    fi
    AC_SUBST(GUILE_SITE)
])

AC_DEFUN([GUILE_PROGS], [
    AC_PATH_PROG(GUILE,guile)
    _guile_required_version="m4_default([$1], [$GUILE_EFFECTIVE_VERSION])"
    if test -z "$_guile_required_version"; then
        _guile_required_version=3.0
    fi
    if test "$GUILE" = "" ; then
        AC_MSG_ERROR([guile required but not found])
    fi
    AC_SUBST(GUILE)

    _guile_effective_version=`$GUILE -c "(display (effective-version))"`
    if test -z "$GUILE_EFFECTIVE_VERSION"; then
        GUILE_EFFECTIVE_VERSION=$_guile_effective_version
    elif test "$GUILE_EFFECTIVE_VERSION" != "$_guile_effective_version"; then
        AC_MSG_ERROR([found development files for Guile $GUILE_EFFECTIVE_VERSION, but $GUILE has effective version $_guile_effective_version])
    fi

    _guile_major_version=`$GUILE -c "(display (major-version))"`
    _guile_minor_version=`$GUILE -c "(display (minor-version))"`
    _guile_micro_version=`$GUILE -c "(display (micro-version))"`
    _guile_prog_version="$_guile_major_version.$_guile_minor_version.$_guile_micro_version"

    AC_MSG_CHECKING([for Guile version >= $_guile_required_version])
    _major_version=`echo $_guile_required_version | cut -d . -f 1`
    _minor_version=`echo $_guile_required_version | cut -d . -f 2`
    _micro_version=`echo $_guile_required_version | cut -d . -f 3`
    if test "$_guile_major_version" -gt "$_major_version"; then
        true
    elif test "$_guile_major_version" -eq "$_major_version"; then
        if test "$_guile_minor_version" -gt "$_minor_version"; then
            true
        elif test "$_guile_minor_version" -eq "$_minor_version"; then
            if test -n "$_micro_version"; then
                if test "$_guile_micro_version" -lt "$_micro_version"; then
                    AC_MSG_ERROR([Guile $_guile_required_version required, but $_guile_prog_version found])
                fi
            fi
        elif test "$GUILE_EFFECTIVE_VERSION" = "$_major_version.$_minor_version" -a -z "$_micro_version"; then
            # Allow prereleases that have the right effective version.
            true
        else
            as_fn_error $? "Guile $_guile_required_version required, but $_guile_prog_version found" "$LINENO" 5
        fi
    else
        AC_MSG_ERROR([Guile $_guile_required_version required, but $_guile_prog_version found])
    fi
    AC_MSG_RESULT([$_guile_prog_version])

    AC_PATH_PROG(GUILD,guild)
    AC_SUBST(GUILD)

    AC_PATH_PROG(GUILE_CONFIG,guile-config)
    AC_SUBST(GUILE_CONFIG)
    if test -n "$GUILD"; then
        GUILE_TOOLS=$GUILD
    else
        AC_PATH_PROG(GUILE_TOOLS,guile-tools)
    fi
    AC_SUBST(GUILE_TOOLS)
])

AC_DEFUN([GUILE_CHECK], [
    AC_REQUIRE([GUILE_PROGS])
    $GUILE -c "$2" > /dev/null 2>&1
    $1=$?
])

AC_DEFUN([GUILE_MODULE_CHECK], [
    AC_MSG_CHECKING([if $2 $4])
    GUILE_CHECK($1,(use-modules $2) (exit ((lambda () $3))))
    if test "$$1" = "0" ; then $1=yes ; else $1=no ; fi
    AC_MSG_RESULT($$1)
])

AC_DEFUN([GUILE_MODULE_AVAILABLE], [GUILE_MODULE_CHECK($1,$2,0,is available)])

AC_DEFUN([GUILE_MODULE_REQUIRED], [
    GUILE_MODULE_AVAILABLE(ac_guile_module_required, ($1))
    if test "$ac_guile_module_required" = "no" ; then
        AC_MSG_ERROR([required guile module not found: ($1)])
    fi
])

AC_DEFUN([GUILE_MODULE_EXPORTS], [GUILE_MODULE_CHECK($1,$2,$3,exports `$3')])

AC_DEFUN([GUILE_MODULE_REQUIRED_EXPORT], [
    GUILE_MODULE_EXPORTS(guile_module_required_export,$1,$2)
    if test "$guile_module_required_export" = "no" ; then
        AC_MSG_ERROR([module $1 does not export $2; required])
    fi
])
