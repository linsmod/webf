/*
 * Copyright (C) 2022-present The WebF authors. All rights reserved.
 */

// type FormDataEntryValue = File | string;
type FormDataPart={}
export interface FormData {
    new():FormData;
    append(name: string, value: BlobPart, fileName?: string): void;
    // This method name is a placeholder of **delete** method to avoid using C++ keyword
    // and will be replaced to **delete** when installing in MemberInstaller::InstallFunctions.
    form_data_delete(name: string): void;
    get(name: string): BlobPart
    getAll(name: string): BlobPart[];
    has(name: string): boolean;
    set(name: string, value: BlobPart, fileName?: string): void;
    forEach(callbackfn: Function, thisArg?: any): void;
    keys():string[]
    values():BlobPart[]
    entries():FormDataPart[]
}
