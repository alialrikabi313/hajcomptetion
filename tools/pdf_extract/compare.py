# -*- coding: utf-8 -*-
import io, os, re, json, sys, difflib, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import parse as P

BASE = os.path.dirname(os.path.abspath(__file__))
PROJ = r'C:\Users\msi\StudioProjects\hajcomptetion'

TOPIC_OF_FILE = {
    'اخر اسئلة الذبح': 'اخر اسئلة الذبح',
    'اسئلة الارشاد بخصوص المخيط': 'اسئلة الارشاد بخصوص المخيط',
    'اسئلة الارشاد حول احرام الحج': 'اسئلة الارشاد حول احرام الحج',
    'اسئلة الارشاد حول مزدلفة': 'اسئلة الارشاد حول مزدلفة',
    'اسئلة الارشاد حول موقف عرفات': 'اسئلة الارشاد حول موقف عرفات',
    'اسئلة التقصير': 'اسئلة التقصير',
    'اسئلة صلاة الطواف': 'اسئلة صلاة الطواف',
    'اسئلة_الارشاد_حول_الذبح_من_مسالة_384_الى_395': 'اسئلة الارشاد حول الذبح من مسالة 384 الى 395',
    'اسئلة_الارشاد_حول_رمي_جمرة_العقبة': 'اسئلة الارشاد حول رمي جمرة العقبة',
    'جميع اسئلة السعي': 'جميع اسئلة السعي',
    'جميع اسئلة الطواف': 'جميع اسئلة الطواف',
}


def sim(a, b):
    return difflib.SequenceMatcher(None, P.norm(a), P.norm(b)).ratio()


def main():
    pdfq = json.load(io.open(os.path.join(BASE, 'pdf_questions.json'), encoding='utf-8'))
    bank = json.load(io.open(os.path.join(PROJ, 'assets', 'haj_questions.json'), encoding='utf-8'))

    by_topic = collections.defaultdict(list)
    for q in pdfq:
        by_topic[TOPIC_OF_FILE[q['file']]].append(q)

    report = []
    used = collections.defaultdict(set)
    for i, b in enumerate(bank):
        topic = b['topic']
        if topic not in by_topic:
            continue                      # PDF-derived (مدرك) question, handled separately
        cands = by_topic[topic]
        best, score = None, 0.0
        for c in cands:
            s = sim(b['question'], c['question'])
            if s > score:
                best, score = c, s
        rec = {'idx': i, 'topic': topic, 'score': round(score, 3),
               'bank_q': b['question'], 'pdf_num': best['num'] if best else None}
        if best is None or score < 0.55:
            rec['issue'] = 'NO_MATCH'
            report.append(rec)
            continue
        used[topic].add(best['num'])
        issues = []
        if score < 0.93:
            issues.append('QUESTION_TEXT')
        # options
        bo, po = b['options'], best['options']
        if len(bo) != len(po):
            issues.append(f'OPTION_COUNT {len(bo)}!={len(po)}')
        else:
            for k, (x, y) in enumerate(zip(bo, po)):
                if sim(x, y) < 0.9:
                    issues.append(f'OPTION{k+1}')
        # correct answer
        ci = bo.index(b['correct_answer']) if b['correct_answer'] in bo else -1
        rec['bank_correct_index'] = ci
        rec['pdf_correct_index'] = best['ans']
        if best['ans'] is None:
            issues.append('PDF_ANSWER_UNPARSED')
        elif ci != best['ans']:
            issues.append('ANSWER')
        if issues:
            rec['issue'] = ','.join(issues)
            rec['pdf_q'] = best['question']
            rec['bank_options'] = bo
            rec['pdf_options'] = po
            rec['bank_answer'] = b['correct_answer']
            rec['pdf_answer'] = po[best['ans']] if best['ans'] is not None and best['ans'] < len(po) else None
            rec['pdf_ref'] = best['ref']
            rec['bank_ref'] = b.get('answer_reference', '')
            report.append(rec)

    # PDF questions not present in the bank
    missing = []
    for topic, qs in by_topic.items():
        for q in qs:
            if q['num'] not in used[topic]:
                missing.append({'topic': topic, 'num': q['num'], 'question': q['question'],
                                'options': q['options'], 'ans': q['ans'], 'ref': q['ref']})

    json.dump(report, io.open(os.path.join(BASE, 'report.json'), 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)
    json.dump(missing, io.open(os.path.join(BASE, 'missing_from_bank.json'), 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)

    kinds = collections.Counter()
    for r in report:
        for k in r['issue'].split(','):
            kinds[k.split()[0]] += 1
    print('bank questions checked:', sum(1 for b in bank if b['topic'] in by_topic))
    print('flagged:', len(report))
    for k, v in kinds.most_common():
        print('   ', k, v)
    print('pdf questions absent from bank:', len(missing))


if __name__ == '__main__':
    main()
