<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:func="http://exslt.org/functions"
                xmlns:otrs="http://otrs.org"
                xmlns:znuny="http://znuny.org"
                extension-element-prefixes="func otrs znuny">

<xsl:import href="ZnunyFunctions.xsl" />

<!-- Deprecated: use ZnunyFunctions.xsl (znuny:*) instead. -->
<func:function name="otrs:date-xsd-to-iso">
    <xsl:param name="date-time" />
    <func:result select="znuny:date-xsd-to-iso($date-time)" />
</func:function>

<!-- Deprecated: use ZnunyFunctions.xsl (znuny:*) instead. -->
<func:function name="otrs:date-iso-to-xsd">
    <xsl:param name="date-time" />
    <func:result select="znuny:date-iso-to-xsd($date-time)" />
</func:function>

</xsl:stylesheet>
