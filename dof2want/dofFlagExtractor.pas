(****************************************************************************
 * dof2want - A convert utility for Want                                    *
 * Copyright (c) 2003 Mike Johnson.                                         *
 * All rights reserved.                                                     *
 *                                                                          *
 * This library is free software; you can redistribute it and/or            *
 * modify it under the terms of the GNU Lesser General Public               *
 * License as published by the Free Software Foundation; either             *
 * version 2.1 of the License, or (at your option) any later version.       *
 *                                                                          *
 * This library is distributed in the hope that it will be useful,          *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU        *
 * Lesser General Public License for more details.                          *
 *                                                                          *
 * You should have received a copy of the GNU Lesser General Public         *
 * License along with this library; if not, write to the Free Software      *
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA *
 ****************************************************************************)
{
    @brief 

    @author Mike Johnson
}
unit dofFlagExtractor;
{
Unit        : dofFlagExtractor

Description : interface for pulling .dof data from a .dof reader

Programmer  : mike

Date        : 11-Dec-2002
}

interface

uses
 classes,
 dofReader;

type
  TDOFFlagExtractor = class(Tobject)
  protected
    fvalues : TStringList;
    freader : TDelphiDOFReader;
  public
    constructor Create(reader : TDelphiDOFReader);
    destructor Destroy; override;
    procedure ExtractValues; virtual; abstract;
    property values : TStringList read fvalues;
  end;
  
implementation

{ TDOFFlagExtractor }

constructor TDOFFlagExtractor.Create(reader: TDelphiDOFReader);
begin
  inherited Create;
  freader := reader;
  fvalues := TStringList.Create;
end;

destructor TDOFFlagExtractor.Destroy;
begin
  fvalues.free;
  inherited;
end;

end.
