"""Regression tests. All claims, reviews and PNGs created here are SYNTHETIC.

They are temporary software fixtures, not novel facts, real artwork, or human
approval. Accepting formal records does not certify the meaning of image pixels.
"""
from pathlib import Path
import copy
import json
import shutil
import struct
import sys
import tempfile
import unittest
import zlib

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / 'tools'))
import cardctl as ct


def chunk(kind, data):
    return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(data,zlib.crc32(kind)) & 0xffffffff)

def png_bytes(w=64,h=96):
    raw=(b'\0'+b'\x80\x80\x80'*w)*h
    return (b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',w,h,8,2,0,0,0))+
            chunk(b'sRGB',b'\0')+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))

class CardWorkflowTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.root=(Path(self.tmp.name)/'repo').resolve()
        # Generated task fixtures and native build products are not inputs to
        # cardctl validation. Excluding them keeps the temporary repository
        # isolated and avoids copying a local SwiftPM build into every case.
        shutil.copytree(REPO,self.root,ignore=shutil.ignore_patterns(
            '__pycache__','reports','SHA256SUMS','.DS_Store','generated','.build'))
        self.path=ct.resolve_card(self.root,'fool:09')
        # The real card can progress. These cases require a synthetic scaffold,
        # not whatever research state happens to be checked into the repository.
        c=self.card()
        c['name_status']='seed_unverified'
        c['production']={'stage':'scaffold','artifact':None,'generation':None,'review_file':None}
        c['cues']=[]
        c['composition'].update(hero_event='',why_this_sequence='',focal_hierarchy=[])
        for dimension,semantic in c['semantics'].items():
            semantic.update(knowledge_state='unresearched',intent='',claim_refs=[],carrier_ids=[],
                            readback='',misreading_guard='',gap_note=None,
                            fidelity='exact' if dimension=='identity' else 'summary')
        self.save(c)

    def tearDown(self):
        self.tmp.cleanup()

    def card(self):
        return ct.load_json(self.path)

    def save(self,c):
        ct.write_json(self.path,c)

    def codes(self,level='scaffold'):
        return {e['code'] for e in ct.validate_card(self.root,self.path,level)}

    def make_design(self):
        """Build internally consistent test records, explicitly not researched canon."""
        c=self.card(); c['name_zh']='程序测试序列名'; c['name_status']='verified'
        c['production']['stage']='directed'
        c['composition'].update(hero_event='程序测试事件：不代表小说设定',why_this_sequence='仅测试数据结构',
                                focal_hierarchy=['主事件','身份','次级线索'])
        reg=ct.load_json(self.root/'catalog/pathways.json')
        reg['pathways'][0]['label_status']='verified'
        ct.write_json(self.root/'catalog/pathways.json',reg)
        src={'id':'synthetic-fixture','kind':'primary_chinese','work_scope':c['work_scope'],'language':'zh-CN',
             'version':'SYNTHETIC TEST ONLY','url':'test-only://no-real-source','retrieval_status':'accessible',
             'accessed_at':'2026-09-10','available_scope':'临时软件测试数据，非原著','notes':'NOT REAL EVIDENCE'}
        ct.write_json(self.root/'sources/registry.json',{'schema_version':'0.3.0','sources':[src]})
        claims=[];c['cues']=[]
        predicates={'identity':'sequence_name','acting':'acting_principle','abilities':'ability',
                    'potion':'potion_ingredient','ascension':'ascension_condition','limitations':'limitation'}
        for i,d in enumerate(ct.DIMS):
            cid='test-'+d; clue='cue-'+d
            value=c['name_zh'] if d=='identity' else '纯测试语义：'+d
            claims.append({'id':cid,'assertion_kind':'canon','predicate':predicates[d],'value':value,'dimensions':[d],'sequences':[9],
                           'work_scope':c['work_scope'],'source_refs':[{'source_id':'synthetic-fixture',
                           'locator':'程序测试位置','support_note':'仅供软件测试，不是真实引用'}],
                           'verification':{'status':'verified','reviewed_by':'synthetic-test-fixture-not-human',
                           'reviewed_at':'2026-09-10T00:00:00+00:00'},'notes':'SYNTHETIC'})
            c['semantics'][d].update(knowledge_state='supported',intent=value,claim_refs=[cid],carrier_ids=[clue],
                                     readback='测试回读 '+d,misreading_guard='不是小说事实')
            channel='text' if d=='identity' else ('object' if d=='potion' else 'action')
            c['cues'].append({'id':clue,'channel':channel,'meaning':value,'implementation':'软件测试载体',
                             'region':{'x':0.1,'y':0.05+i*0.12,'w':0.8,'h':0.1},
                             'decode_mode':'literal' if d=='identity' else 'metaphoric',
                             'exact_text':c['name_zh'] if d=='identity' else None,'legend_ref':None})
        pc=copy.deepcopy(claims[0]);pc.update(id='test-pathway-name',predicate='pathway_name',value=reg['pathways'][0]['working_name_zh'])
        claims.append(pc);c['semantics']['identity']['claim_refs'].append(pc['id'])
        ct.write_json(self.root/'pathways/fool/canon.json',{'schema_version':'0.3.0','pathway_id':'fool','claims':claims,'note':'SYNTHETIC TEST ONLY'})
        self.save(c)
        return c

    def make_release(self):
        c=self.make_design()
        # Use a smaller profile inside temporary tests only; shipped defaults stay 2048x3072.
        cfg=ct.load_json(self.root/'config/project.json');cfg['delivery_profiles']['standard']={'width':64,'height':96}
        ct.write_json(self.root/'config/project.json',cfg)
        d=self.root/'artifacts/lotm.fool.s09/v001';d.mkdir(parents=True,exist_ok=True)
        (d/'final.png').write_bytes(png_bytes());(d/'raw.png').write_bytes(png_bytes())
        final={'path':'artifacts/lotm.fool.s09/v001/final.png','sha256':ct.digest_file(d/'final.png')}
        raw={'path':'artifacts/lotm.fool.s09/v001/raw.png','sha256':ct.digest_file(d/'raw.png')}
        c['production'].update(stage='approved',artifact=final,review_file='artifacts/lotm.fool.s09/v001/review.json',
            generation={'tool':{'name':'synthetic-test-fixture','model':None},'created_at':'2026-09-10T00:00:00+00:00',
                        'raw_assets':[raw],'processing':[],'declared_native':True})
        self.save(c)
        review=ct.load_json(self.root/'templates/review.json')
        review.update(card_id=c['card_id'],design_fingerprint=ct.design_fingerprint(self.root,self.path),
                      image_sha256=final['sha256'],reviewed_by='synthetic-test-fixture-not-human',
                      reviewed_at='2026-09-10T00:00:00+00:00')
        for e in review['checks'].values():
            e.update(status='pass',note='SYNTHETIC RECORD; NOT A REAL VISUAL REVIEW')
        for d in ct.DIMS:
            review['semantic_readback'][d].update(status='pass',observed_cue_ids=c['semantics'][d]['carrier_ids'],
                                                 observation='Synthetic fixture, not actually readable art')
        review['approval'].update(status='approved',by='synthetic-fixture-not-user',at='2026-09-10T00:00:00+00:00',
                                  reference='unit-test-only: not a real approval')
        ct.write_json(self.root/c['production']['review_file'],review)
        return c

    def edit_claims(self,fn):
        p=self.root/'pathways/fool/canon.json';data=ct.load_json(p);fn(data['claims']);ct.write_json(p,data)

    def test_scaffold_has_exact_22_by_10(self):
        r=ct.check_repository(self.root)
        self.assertTrue(r['passed'],r['errors']);self.assertEqual(r['cards_checked'],220)
        self.assertLess(r['max_agent_chain_bytes'],32768)

    def test_scaffold_cards_have_all_six_dimensions_but_no_fake_art(self):
        for p in (self.root/'pathways').glob('*/sequences/*/card.json'):
            c=ct.load_json(p);self.assertEqual(set(c['semantics']),set(ct.DIMS))
            if c['production']['stage'] == 'scaffold':
                self.assertIsNone(c['production']['artifact'])
        self.assertEqual(ct.status(self.root)['artifact_files_present'],1)

    def test_22_original_shape_proposals_are_distinct(self):
        shapes=[ct.load_json(self.root/f'pathways/{s}/direction.json')['shape_language'] for s in ct.PATH_IDS]
        self.assertEqual(len(set(shapes)),22)

    def test_missing_card_slot_fails(self):
        self.path.unlink();r=ct.check_repository(self.root)
        self.assertIn('inventory.cards',{x['code'] for x in r['errors']})

    def test_duplicate_pathway_fails(self):
        p=self.root/'catalog/pathways.json';r=ct.load_json(p);r['pathways'][1]['id']='fool';ct.write_json(p,r)
        self.assertIn('registry.pathways',{x['code'] for x in ct.check_repository(self.root)['errors']})

    def test_missing_semantic_dimension_fails(self):
        c=self.card();del c['semantics']['potion'];self.save(c)
        self.assertIn('semantics.six_required',self.codes())

    def test_card_identity_mismatch_fails(self):
        c=self.card();c['card_id']='lotm.error.s09';self.save(c)
        self.assertIn('card.identity',self.codes())

    def test_boolean_is_not_a_sequence_integer(self):
        c=self.card();c['sequence']=True;self.save(c)
        self.assertIn('card.identity',self.codes())

    def test_unknown_profile_fails(self):
        c=self.card();c['delivery_profile']='pretend-8k';self.save(c)
        self.assertIn('card.profile',self.codes())

    def test_unresearched_design_is_blocked(self):
        self.assertIn('design.unresearched',self.codes('design'))

    def test_synthetic_mixed_media_design_is_structurally_accepted(self):
        self.make_design();self.assertEqual(self.codes('design'),set())

    def test_missing_carrier_reference_fails(self):
        c=self.make_design();c['semantics']['potion']['carrier_ids']=['does-not-exist'];self.save(c)
        self.assertIn('cue.dangling',self.codes('design'))

    def test_six_dimensions_cannot_share_one_generic_cue(self):
        c=self.make_design();c['cues']=c['cues'][:1]
        for d in ct.DIMS:c['semantics'][d]['carrier_ids']=[c['cues'][0]['id']]
        self.save(c);self.assertIn('semantics.generic_all_six',self.codes('design'))

    def test_single_event_can_cover_two_dimensions(self):
        c=self.make_design();c['semantics']['acting']['carrier_ids']=['cue-abilities']
        c['cues']=[q for q in c['cues'] if q['id']!='cue-acting'];self.save(c)
        self.assertEqual(self.codes('design'),set())

    def test_precise_identity_cannot_be_only_lighting(self):
        c=self.make_design();q=c['cues'][0];q.update(channel='lighting',exact_text=None,decode_mode='metaphoric');self.save(c)
        self.assertIn('design.exact_carrier',self.codes('design'))

    def test_summary_can_use_style_without_text_when_plan_is_explicit(self):
        c=self.make_design();c['cues'][-1]['channel']='material';self.save(c)
        self.assertEqual(self.codes('design'),set())

    def test_region_overflow_fails(self):
        c=self.make_design();c['cues'][0]['region']['w']=1.0;self.save(c)
        self.assertIn('cue.region',self.codes('design'))

    def test_text_requires_exact_copy(self):
        c=self.make_design();c['cues'][0]['exact_text']=None;self.save(c)
        self.assertIn('cue.exact_text',self.codes('design'))

    def test_project_legend_must_exist(self):
        c=self.make_design();c['cues'][0].update(decode_mode='project_legend',legend_ref='missing-legend.md');self.save(c)
        self.assertIn('cue.legend',self.codes('design'))

    def test_documented_absence_is_not_unknown(self):
        c=self.make_design();c['semantics']['ascension'].update(knowledge_state='documented_absence',gap_note='just did not find it');self.save(c)
        self.assertIn('design.unsupported_absence',self.codes('design'))

    def test_partial_requires_explicit_gap_scope(self):
        c=self.make_design();c['semantics']['potion']['knowledge_state']='partial';self.save(c)
        self.assertIn('design.gap_scope',self.codes('design'))

    def test_wrong_sequence_claim_fails(self):
        self.make_design();self.edit_claims(lambda cs:cs[2].update(sequences=[0]))
        self.assertIn('design.claim_scope',self.codes('design'))

    def test_unverified_claim_fails(self):
        self.make_design();self.edit_claims(lambda cs:cs[2]['verification'].update(status='lead'))
        self.assertIn('design.claim_unverified',self.codes('design'))

    def test_english_source_cannot_verify_chinese_name(self):
        self.make_design();p=self.root/'sources/registry.json';s=ct.load_json(p)
        s['sources'][0].update(kind='primary_translation',work_scope='lotm-volume-1-en');ct.write_json(p,s)
        self.assertIn('design.primary_required',self.codes('design'))

    def test_inaccessible_source_cannot_be_claimed_read(self):
        self.make_design();p=self.root/'sources/registry.json';s=ct.load_json(p)
        s['sources'][0]['retrieval_status']='inaccessible';ct.write_json(p,s)
        self.assertIn('design.source_inaccessible',self.codes('design'))

    def test_normal_brief_blocked_on_scaffold(self):
        with self.assertRaises(ct.DataError):ct.build_brief(self.root,'fool:09')

    def test_draft_brief_outputs_five_files_with_warning(self):
        source_hash=ct.digest_file(self.path)
        out=ct.build_brief(self.root,'fool:09',draft=True)
        self.assertEqual({p.name for p in out.iterdir()},
                         {'task.md','art-brief.md','overlay-copy.json','semantic-checklist.md','dependencies.json'})
        self.assertIn('DRAFT / RESEARCH',(out/'task.md').read_text())
        self.assertEqual(source_hash,ct.digest_file(self.path))

    def test_brief_includes_sequence_hierarchy_label(self):
        out=ct.build_brief(self.root,'fool:00',draft=True,slim=True)
        text=(out/'task.md').read_text()
        self.assertIn('序列0 · 愚者 · 真神',text)

    def test_valid_design_brief_keeps_single_card_scope(self):
        self.make_design();out=ct.build_brief(self.root,'fool:09')
        text=(out/'task.md').read_text();self.assertIn('DESIGN-CHECKED',text)
        self.assertNotIn('lotm.error.s09',text)

    def test_fingerprint_ignores_only_production_bookkeeping(self):
        before=ct.design_fingerprint(self.root,self.path)
        c=self.card();c['production']['stage']='research';self.save(c)
        self.assertEqual(before,ct.design_fingerprint(self.root,self.path))
        c['semantics']['acting']['intent']='changed';self.save(c)
        self.assertNotEqual(before,ct.design_fingerprint(self.root,self.path))

    def test_fake_approved_stage_cannot_bypass_checks(self):
        c=self.make_design();c['production']['stage']='approved';self.save(c)
        self.assertIn('release.review_missing',self.codes('scaffold'))

    def test_record_fields_can_pass_without_certifying_image_meaning(self):
        self.make_release();self.assertEqual(self.codes('release'),set())

    def test_wrong_real_dimensions_fails(self):
        c=self.make_release();p=self.root/c['production']['artifact']['path'];p.write_bytes(png_bytes(32,48))
        c['production']['artifact']['sha256']=ct.digest_file(p);self.save(c)
        self.assertIn('release.dimensions',self.codes('release'))

    def test_false_native_upscale_fails(self):
        c=self.make_release();c['production']['generation']['processing']=[{'operation':'upscale','description':'test only'}];self.save(c)
        self.assertIn('release.false_native',self.codes('release'))

    def test_file_hash_mismatch_fails(self):
        c=self.make_release();c['production']['artifact']['sha256']='a'*64;self.save(c)
        self.assertIn('asset.hash_mismatch',self.codes('release'))

    def test_stale_design_review_fails(self):
        c=self.make_release();c['semantics']['abilities']['intent']+='changed';self.save(c)
        self.assertIn('release.stale_design',self.codes('release'))

    def test_missing_actual_review_does_not_pass(self):
        c=self.make_release();p=self.root/c['production']['review_file'];r=ct.load_json(p)
        r['checks']['art_direction']['status']='not_run';ct.write_json(p,r)
        self.assertIn('release.check_not_passed',self.codes('release'))

    def test_missing_approval_evidence_fails(self):
        c=self.make_release();p=self.root/c['production']['review_file'];r=ct.load_json(p)
        r['approval']['reference']=None;ct.write_json(p,r)
        self.assertIn('release.approval',self.codes('release'))

    def test_png_corrupt_crc_is_rejected(self):
        p=self.root/'bad.png';data=bytearray(png_bytes());data[-1]^=1;p.write_bytes(data)
        with self.assertRaises(ct.DataError):ct.image_info(p)

    def test_fake_png_header_without_image_is_rejected(self):
        p=self.root/'fake.png';p.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',64,96,8,2,0,0,0)))
        with self.assertRaises(ct.DataError):ct.image_info(p)

    def test_paths_cannot_escape_repository(self):
        with self.assertRaises(ct.DataError):ct.safe_path(self.root,'../secret.txt',must_exist=False)
        with self.assertRaises(ct.DataError):ct.safe_path(self.root,'/tmp/secret.txt',must_exist=False)

    def test_unknown_card_selector_is_rejected(self):
        with self.assertRaises(ct.DataError):ct.resolve_card(self.root,'fool:10')
        with self.assertRaises(ct.DataError):ct.resolve_card(self.root,'../fool:09')

    def test_duplicate_json_keys_are_rejected(self):
        p=self.root/'duplicate.json';p.write_text('{"a":1,"a":2}')
        with self.assertRaises(ct.DataError):ct.load_json(p)

    def test_nan_is_not_valid_json(self):
        p=self.root/'bad.json';p.write_text('{"a":NaN}')
        with self.assertRaises(ct.DataError):ct.load_json(p)

    def test_manifest_detects_modified_file(self):
        p=self.root/'manifest-test.txt';p.write_text('original')
        (self.root/'SHA256SUMS').write_text(ct.digest_file(p)+'  manifest-test.txt\n')
        self.assertTrue(ct.verify_manifest(self.root)['passed'])
        p.write_text('changed');self.assertFalse(ct.verify_manifest(self.root)['passed'])


    def test_interpretation_cannot_masquerade_as_exact_name(self):
        self.make_design();self.edit_claims(lambda cs:cs[0].update(assertion_kind='interpretation'))
        self.assertIn('design.interpretation_exact',self.codes('design'))

    def test_unrecorded_enlargement_fails(self):
        c=self.make_release();p=self.root/c['production']['generation']['raw_assets'][0]['path']
        p.write_bytes(png_bytes(32,48));c['production']['generation']['raw_assets'][0]['sha256']=ct.digest_file(p)
        c['production']['generation']['declared_native']=False;self.save(c)
        self.assertIn('release.unrecorded_resize',self.codes('release'))

    def test_generated_symlink_cannot_escape(self):
        target=Path(self.tmp.name)/'outside';target.mkdir()
        gen=self.root/'generated/lotm.fool.s09';gen.parent.mkdir(parents=True,exist_ok=True)
        gen.symlink_to(target,target_is_directory=True)
        with self.assertRaises(ct.DataError):ct.build_brief(self.root,'fool:09',draft=True)
        self.assertEqual(list(target.iterdir()),[])

    def test_wrong_pathway_direction_is_rejected(self):
        p=self.root/'pathways/fool/direction.json';o=ct.load_json(p);o['pathway_id']='error';ct.write_json(p,o)
        self.assertIn('direction.contract',{x['code'] for x in ct.check_repository(self.root)['errors']})

if __name__=='__main__':
    unittest.main()
