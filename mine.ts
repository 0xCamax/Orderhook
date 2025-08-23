import { mine, HookFlag } from './lib/hookminerScript/src/mod.ts';

const flags: HookFlag[] = [HookFlag.BEFORE_ADD_LIQUIDITY];
const bytecode = '0x';
const constructorArgs = {
	types: [],
	value: [],
} as { types: string[]; value: any[] };

mine(flags, bytecode, constructorArgs);
