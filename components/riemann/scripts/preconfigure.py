#!/usr/bin/env python

from os.path import join, dirname

from cloudify import ctx


ctx.source.instance.runtime_properties['rest_host'] = \
    ctx.target.instance.runtime_properties['internal_rest_host']