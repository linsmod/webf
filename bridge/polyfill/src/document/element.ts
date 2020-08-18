import { BODY } from './events/event-target';
import { Node, NodeType, traverseNode } from './node';
import { addElementById, removeElementById } from './getElementById';

import {
  createElement,
  setProperty,
  removeProperty,
  setStyle,
  method,
  toBlob,
  getProperty
} from './ui-manager';

const RECT_PROPERTIES = [
  'offsetTop',
  'offsetLeft',
  'offsetWidth',
  'offsetHeight',

  'clientWidth',
  'clientHeight',
  'clientLeft',
  'clientTop',

  'scrollTop',
  'scrollLeft',
  'scrollHeight',
  'scrollWidth',
];

interface ICamelize {
  (str: string): string;
}

/**
 * Create a cached version of a pure function.
 */
function cached(fn: ICamelize) {
  const cache = Object.create(null);
  return function cachedFn(str : string) {
    const hit = cache[str];
    return hit || (cache[str] = fn(str));
  };
};

/**
 * Camelize a hyphen-delimited string.
 */
const camelize: ICamelize = (str: string) => {
  const camelizeRE = /-(\w)/g;
  return str.replace(camelizeRE, function (_: string, c: string) {
    return c ? c.toUpperCase() : '';
  });
}

// Cached camelize utility
const cachedCamelize = cached(camelize);
// support event handlers using 'on' property prefix.
const elementBuildInEvents = ['click', 'appear', 'disappear', 'touchstart', 'touchmove', 'touchend', 'touchcancel'];

class StyleDeclaration {
  private targetId: number;
  constructor(targetId: number) {
    this.targetId = targetId;
  }
  setProperty(property: string, value: any) {
    const camelizedProperty = cachedCamelize(property);
    this[camelizedProperty] = value;
    setStyle(this.targetId, camelizedProperty, value);
  }
  removeProperty(property: string) {
    const camelizedProperty = cachedCamelize(property);
    setStyle(this.targetId, camelizedProperty, '');
    const originValue = this[camelizedProperty];
    this[camelizedProperty] = '';
    return originValue;
  }
  getPropertyValue(property: string) {
    const camelizedProperty = cachedCamelize(property);
    return this[camelizedProperty];
  }
}

export class Element extends Node {
  public readonly tagName: string;
  public style: StyleDeclaration;
  // TODO use NamedNodeMap: https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap
  public attributes: Array<any> = [];

  constructor(tagName: string, _targetId?: number, builtInEvents?: Array<string>, builtInProperties?: Array<string>) {
    super(NodeType.ELEMENT_NODE, _targetId, elementBuildInEvents.concat(builtInEvents || []));
    this.tagName = tagName.toUpperCase();
    const targetId = this.targetId;
    const style = this.style = new StyleDeclaration(targetId);
    // FIXME: Proxy not support in iOS 9.x
    // See: https://caniuse.com/#search=proxy
    this.style = new Proxy(style, {
      set(target: any, key: string, value: any, receiver: any): boolean {
        style.setProperty(key, value);
        return true;
      },
      get(target: any, key: string, receiver) {
        // Proxy to prototype method
        if (key in target) {
          return target[key];
        }
        return style.getPropertyValue(key);
      },
    });

    // Define rect properties
    for (let i = 0; i < RECT_PROPERTIES.length; i++) {
      const prop = RECT_PROPERTIES[i];
      Object.defineProperty(this, prop, {
        configurable: false,
        enumerable: true,
        get() {
          return Number(method(targetId, prop));
        },
      });
    }

    if (Array.isArray(builtInProperties)) {
      builtInProperties.forEach(property => {
        Object.defineProperty(this, property, {
          get() {
            return this.getAttribute(property);
          },
          set(value) {
            this.setAttribute(property, value);
          }
        });
      });
    }

    // Body is created automaticlly.
    if (this.targetId != BODY) {
      createElement(this.tagName, targetId);
    }
  }

  getBoundingClientRect = () => {
    const rectInformation = method(this.targetId, 'getBoundingClientRect');
    if (typeof rectInformation === 'string') {
      return JSON.parse(rectInformation);
    } else {
      return null;
    }
  }

  get nodeName() {
    return this.tagName.toUpperCase();
  }

  public setAttribute(name: string, value: string) {
    // The attribute name is automatically converted to
    // all lower-case when setAttribute() is called on an HTML element in an HTML document
    name = String(name).toLowerCase();
    value = String(value);
    if (this.attributes[name]) {
      const oldValue = this.attributes[name].value;
      this.attributes[name].value = value;
      this._didModifyAttribute(name, oldValue, value);
    } else {
      const attr = {name, value};
      this.attributes[name] = attr;
      this.attributes.push(attr);
      this._didModifyAttribute(name, '', value);
    }
    setProperty(this.targetId, name, value);
  }

  protected _notifyNodeRemoved(insertionNode: Node): void {
    if (insertionNode.isConnected) {
      traverseNode(this, (node: Node) => {
        if (node instanceof Element) {
          node._notifyChildRemoved();
        }
      });
    }
  }

  protected _notifyChildRemoved(): void {
    if (this.hasAttribute('id')) {
      const elementid = this.getAttribute('id');
      this._updateId(elementid, null);
    }
  }

  protected _notifyNodeInsert(insertionNode: Node): void {
    if (insertionNode.isConnected) {
      traverseNode(this, (node: Node) => {
        if( node instanceof Element) {
          node._notifyChildInsert();
        }
      });
    }
  }

  protected _notifyChildInsert(): void {
    if (this.hasAttribute('id')) {
      const elementid = this.getAttribute('id');
      this._updateId(null, elementid);
    }
  }

  private _didModifyAttribute(name: string, oldValue: string, newValue: string): void {
    if (name === 'id') {
      this._beforeUpdateId(oldValue, newValue);
    }
  }

  private _beforeUpdateId(oldValue: string, newValue: string): void {
    if (!this.isConnected) {
      return;
    }
    if (oldValue === newValue) {
      return;
    }
    this._updateId(oldValue, newValue);

  }
  private _updateId(oldValue: string | null, newValue: string | null): void {
    if (oldValue) {
      removeElementById(oldValue, this);
    }
    if (newValue) {
      addElementById(newValue, this);
    }
  }

  public getAttribute(name: string) {
    name = String(name);
    if (this.attributes[name]) {
      return this.attributes[name].value;
    }
    return getProperty(this.targetId, name);
  }

  public hasAttribute(name: string) {
    name = String(name);
    return Boolean(this.attributes[name]);
  }

  public removeAttribute(name: string) {
    if (this.attributes[name]) {
      const attr = this.attributes[name];
      const idx = this.attributes.indexOf(attr);
      if (idx !== -1) {
        this.attributes.splice(idx, 1);
        this._didModifyAttribute(name, attr.value, '');
      }

      removeProperty(this.targetId, name);
      delete this.attributes[name];
    }
  }

  public click() {
    method(this.targetId, 'click');
  }

  async toBlob(devicePixelRatio: number = window.devicePixelRatio) {
    return toBlob(this.targetId, devicePixelRatio);
  }

  public scroll(x: number | any, y?: number) {
    let option = x;
    if (typeof x === 'number') {
      option = {
        'top': y,
        'left': x
      };
    }
    method(this.targetId, 'scroll', [option]);
  }

  public scrollTo(x: number | any, y?: number) {
    if (typeof y === 'number') {
      scroll(x, y);
    } else {
      scroll(x, 0);
    }
  }

  public scrollBy(x: number | any, y?: number) {
    let option = x;
    if (typeof x === 'number') {
      option = {
        'top': y,
        'left': x
      };
    }
    method(this.targetId, 'scrollBy', [option]);
  }
}
