# -*- coding: utf-8 -*-
"""Parse decoded PDF text into question records."""
import re, unicodedata

AR_DIAC = re.compile(r'[\u064b-\u0652\u0670\u0640]')
ORD = {'الأول': 0, 'الاول': 0, 'الثاني': 1, 'الثانى': 1, 'الثالث': 2, 'الرابع': 3}

Q_START = re.compile(r'^[\.\s]*[٠-٩۰-۹0-9]+\s*[\.\s]*\s*[سص]\s*/\s*[٠-٩۰-۹0-9]+')
OPT = re.compile(r'(?:^|\s)([أابجد])\s*[ـ\-–]\s*')
ANS = re.compile(r'الجواب\s*الصحيح\s*ه\s*و\s*(الأول|الاول|الثاني|الثانى|الثالث|الرابع)')


def strip_diac(s):
    return AR_DIAC.sub('', s)


def norm(s):
    s = strip_diac(s)
    s = s.replace('ھ', 'ه').replace('ﻩ', 'ه').replace('ہ', 'ه')
    s = s.replace('ي', 'ي').replace('ی', 'ي').replace('ى', 'ي')
    s = s.replace('أ', 'ا').replace('إ', 'ا').replace('آ', 'ا').replace('ٱ', 'ا')
    s = s.replace('ة', 'ه').replace('ؤ', 'و').replace('ئ', 'ي')
    s = s.replace('(', '').replace(')', '').replace('"', '').replace('،', ',')
    s = re.sub(r'[\.\:\-–\u0640،؛,]+', ' ', s)
    s = re.sub(r'\s+', ' ', s)
    return s.strip()


def is_noise(line):
    t = line.strip()
    if not t or t.startswith('@@PAGE'):
        return True
    if set(t) <= set(' \u064b\u064c\u064d\u064e\u064f\u0650\u0651\u0652\u0670ًٌٍَُِّْ'):
        return True
    if '........' in t:
        return True
    if re.fullmatch(r'[\s\)\(٠-٩0-9]+', t):
        return True
    return False
