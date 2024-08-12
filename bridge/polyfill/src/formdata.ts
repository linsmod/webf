import {webf} from './webf';
export class FormData{
    private id:string;
    constructor(){
        this.id = webf.invokeModule('FormData', 'init');
    }
    public append(name:string,value:any):void{
        webf.invokeModule('FormData','append',[this.id,name,value]);
    }
    public toString():string{
        return webf.invokeModule('FormData','toString',[this.id]);
    }
    public getAll():any[]{
        return webf.invokeModule('FormData','getAll',[this.id]);
    }
    public getFirst():any{
        return webf.invokeModule('FormData','getFirst',[this.id]);
    }
}