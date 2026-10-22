import {LuauState} from 'luau-web';
import {readFile,readdir} from 'node:fs/promises';
import {join,relative} from 'node:path';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('..',import.meta.url));
async function files(path) {
 const result=[];
 for(const e of await readdir(path,{withFileTypes:true})) {
  if(e.isDirectory()) result.push(...await files(join(path,e.name)));
  else if(e.name.endsWith('.luau')) result.push(join(path,e.name));
 }
 return result;
}
const state=await LuauState.createAsync({print:console.log,warn:console.warn});
try {
 const sources=await files(join(root,'src'));
 for(const file of sources) state.loadstring(await readFile(file,'utf8'),relative(root,file),true);
 console.log(`PASS: ${sources.length} Luau sources compile`);
 let harness=await readFile(join(root,'tests/prelude.luau'),'utf8');
 for(const name of ['Kanto','Config','Rules','PokemonDatabase','AbilityDatabase','PokemonModelSettings']) {
  harness+=`\nmodules["${name}"]=(function()\n${await readFile(join(root,`src/shared/${name}.luau`),'utf8')}\nend)()\n`;
 }
 for(const name of ['EconomyService','MatchmakingService','CombatService','MatchService','DataService','LeaderboardService']) {
  harness+=`\nmodules["${name}"]=(function()\n${await readFile(join(root,`src/server/${name}.luau`),'utf8')}\nend)()\n`;
 }
 harness+=await readFile(join(root,'tests/spec.luau'),'utf8');
 await state.loadstring(harness,'domain-tests',true)();
 const clientTest=(await readFile(join(root,'tests/client_startup.luau'),'utf8')).replace('-- BOOTSTRAP --',await readFile(join(root,'src/client/Bootstrap.client.luau'),'utf8'));
 await state.loadstring(clientTest,'client-startup-regression',true)();
} finally {state.destroy();}
